import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const sampleRate = 44100;

double envelope(
  int index,
  int length, {
  double attack = .03,
  double release = .18,
}) {
  final position = index / length;
  final fadeIn = (position / attack).clamp(0.0, 1.0);
  final fadeOut = ((1 - position) / release).clamp(0.0, 1.0);
  return min(fadeIn, fadeOut);
}

List<double> tone(double frequency, double seconds, {double volume = .5}) {
  final length = (sampleRate * seconds).round();
  return List.generate(length, (index) {
    final wave = sin(2 * pi * frequency * index / sampleRate);
    final sparkle = .22 * sin(2 * pi * frequency * 2 * index / sampleRate);
    return (wave + sparkle) * envelope(index, length) * volume;
  });
}

List<double> sweep(
  double from,
  double to,
  double seconds, {
  double volume = .45,
}) {
  final length = (sampleRate * seconds).round();
  var phase = 0.0;
  return List.generate(length, (index) {
    final t = index / length;
    phase += 2 * pi * (from + (to - from) * t) / sampleRate;
    return sin(phase) *
        envelope(index, length, attack: .02, release: .25) *
        volume;
  });
}

List<double> silence(double seconds) =>
    List.filled((sampleRate * seconds).round(), 0);

List<double> sequence(List<List<double>> parts) => [
  for (final part in parts) ...part,
];

List<double> heistBed({required bool tension}) {
  const seconds = 6.0;
  final length = (sampleRate * seconds).round();
  final rng = Random(tension ? 7331 : 1904);
  var lowPhase = 0.0;
  var pulsePhase = 0.0;
  return List.generate(length, (index) {
    final t = index / sampleRate;
    lowPhase += 2 * pi * (tension ? 58 : 46) / sampleRate;
    pulsePhase += 2 * pi * (tension ? 3.5 : 1.5) / sampleRate;
    final bass = sin(lowPhase) * (tension ? .13 : .09);
    final pulse = pow(max(0.0, sin(pulsePhase)), 8) * (tension ? .12 : .035);
    final shimmer = (rng.nextDouble() * 2 - 1) * .012;
    final loopFade = min(
      (t / .15).clamp(0.0, 1.0),
      ((seconds - t) / .15).clamp(0.0, 1.0),
    );
    return (bass + pulse + shimmer) * loopFade;
  });
}

List<double> mechanicalTick({required int intensity}) {
  final seconds = .075 + intensity * .012;
  final length = (sampleRate * seconds).round();
  final rng = Random(4100 + intensity);
  var bodyPhase = 0.0;
  var metalPhase = 0.0;
  return List.generate(length, (index) {
    final t = index / sampleRate;
    bodyPhase += 2 * pi * (310 + intensity * 55) / sampleRate;
    metalPhase += 2 * pi * (1900 + intensity * 380) / sampleRate;
    final transient = (rng.nextDouble() * 2 - 1) * exp(-t * 95);
    final body = sin(bodyPhase) * exp(-t * 42);
    final metal = sin(metalPhase) * exp(-t * 58);
    final secondClickTime = t - .038;
    final secondClick = intensity == 2 && secondClickTime >= 0
        ? sin(2 * pi * 2450 * secondClickTime) * exp(-secondClickTime * 105)
        : 0.0;
    final attack = (t / .0015).clamp(0.0, 1.0);
    return (transient * .5 + body * .34 + metal * .25 + secondClick * .22) *
        attack *
        (.72 + intensity * .12);
  });
}

List<double> bombExplosion() {
  const seconds = 1.55;
  final length = (sampleRate * seconds).round();
  final rng = Random(8675309);
  var rumblePhase = 0.0;
  var filteredNoise = 0.0;
  return List.generate(length, (index) {
    final t = index / sampleRate;
    final progress = t / seconds;
    final rumbleFrequency = 88 - 48 * progress;
    rumblePhase += 2 * pi * rumbleFrequency / sampleRate;

    final rawNoise = rng.nextDouble() * 2 - 1;
    filteredNoise += (rawNoise - filteredNoise) * .075;
    final crack = rawNoise * exp(-t * 19);
    final blast = filteredNoise * exp(-t * 2.7);
    final rumble =
        (sin(rumblePhase) + .35 * sin(rumblePhase * .51)) * exp(-t * 2.15);

    var debris = 0.0;
    for (final hit in const [.18, .31, .47, .69, .92]) {
      final sinceHit = t - hit;
      if (sinceHit >= 0 && sinceHit < .075) {
        debris +=
            sin(2 * pi * (720 - hit * 280) * sinceHit) *
            exp(-sinceHit * 58) *
            .16;
      }
    }

    final attack = (t / .004).clamp(0.0, 1.0);
    final tail = ((seconds - t) / .22).clamp(0.0, 1.0);
    return (crack * .72 + blast * .9 + rumble * .48 + debris) * attack * tail;
  });
}

void writeWave(String name, List<double> samples) {
  final dataSize = samples.length * 2;
  final bytes = ByteData(44 + dataSize);
  void text(int offset, String value) {
    for (var i = 0; i < value.length; i++) {
      bytes.setUint8(offset + i, value.codeUnitAt(i));
    }
  }

  text(0, 'RIFF');
  bytes.setUint32(4, 36 + dataSize, Endian.little);
  text(8, 'WAVE');
  text(12, 'fmt ');
  bytes.setUint32(16, 16, Endian.little);
  bytes.setUint16(20, 1, Endian.little);
  bytes.setUint16(22, 1, Endian.little);
  bytes.setUint32(24, sampleRate, Endian.little);
  bytes.setUint32(28, sampleRate * 2, Endian.little);
  bytes.setUint16(32, 2, Endian.little);
  bytes.setUint16(34, 16, Endian.little);
  text(36, 'data');
  bytes.setUint32(40, dataSize, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    bytes.setInt16(
      44 + i * 2,
      (samples[i].clamp(-1.0, 1.0) * 32767).round(),
      Endian.little,
    );
  }
  File('assets/sounds/$name.wav').writeAsBytesSync(bytes.buffer.asUint8List());
}

void main() {
  writeWave('tick_calm', mechanicalTick(intensity: 0));
  writeWave('tick_tense', mechanicalTick(intensity: 1));
  writeWave('tick_critical', mechanicalTick(intensity: 2));
  writeWave('boom', bombExplosion());
  writeWave('select', sequence([tone(660, .07), tone(990, .11)]));
  writeWave('start', sequence([tone(520, .08), silence(.025), tone(780, .12)]));
  writeWave(
    'reveal',
    sequence([
      tone(523.25, .08, volume: .32),
      tone(659.25, .08, volume: .36),
      tone(783.99, .16, volume: .42),
    ]),
  );
  writeWave('skip', sweep(720, 260, .22));
  writeWave(
    'turn',
    sequence([
      tone(440, .08, volume: .38),
      silence(.05),
      tone(587.33, .13, volume: .44),
    ]),
  );
  writeWave(
    'heist_alarm',
    sequence([
      sweep(420, 920, .18, volume: .38),
      silence(.06),
      sweep(420, 920, .18, volume: .38),
    ]),
  );
  writeWave(
    'heist_vault',
    sequence([
      tone(110, .18, volume: .28),
      tone(165, .22, volume: .3),
      silence(.05),
      sweep(280, 820, .45, volume: .36),
    ]),
  );
  writeWave(
    'heist_cash',
    sequence([
      for (var i = 0; i < 5; i++) ...[
        tone(900 + i * 115, .055, volume: .24),
        silence(.025),
      ],
    ]),
  );
  writeWave(
    'heist_betrayal',
    sequence([sweep(760, 120, .62, volume: .42), tone(92, .24, volume: .3)]),
  );
  writeWave('heist_planning', heistBed(tension: false));
  writeWave('heist_tension', heistBed(tension: true));
}
