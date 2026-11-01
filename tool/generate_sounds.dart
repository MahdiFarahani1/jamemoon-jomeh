import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

// Generate valid standard PCM WAV files for game sound effects
void main() {
  final soundsDir = Directory('assets/sounds');
  if (!soundsDir.existsSync()) {
    soundsDir.createSync(recursive: true);
  }

  // 1. Tick sound (short crisp click / beep)
  generateWav(
    path: 'assets/sounds/tick.wav',
    durationSeconds: 0.06,
    sampleRate: 22050,
    generator: (t) => sin(2 * pi * 880 * t) * exp(-t * 50),
  );

  // 2. Boom / Explosion sound (low frequency thud + decaying noise)
  final random = Random(42);
  generateWav(
    path: 'assets/sounds/boom.wav',
    durationSeconds: 0.8,
    sampleRate: 22050,
    generator: (t) {
      final freq = 120.0 * (1.0 - t / 0.8);
      final sine = sin(2 * pi * freq * t);
      final noise = (random.nextDouble() * 2 - 1) * 0.4;
      return (sine * 0.7 + noise) * exp(-t * 4);
    },
  );

  // 3. Buzzer / Wrong sound (harsh low tone)
  generateWav(
    path: 'assets/sounds/buzzer.wav',
    durationSeconds: 0.35,
    sampleRate: 22050,
    generator: (t) {
      final sine1 = sin(2 * pi * 150 * t);
      final sine2 = sin(2 * pi * 225 * t);
      return (sine1 * 0.6 + sine2 * 0.4) * exp(-t * 2);
    },
  );

  // 4. Correct sound (bright happy ding / chime)
  generateWav(
    path: 'assets/sounds/correct.wav',
    durationSeconds: 0.4,
    sampleRate: 22050,
    generator: (t) {
      final f = t < 0.15 ? 587.33 : 880.0; // D5 to A5
      return sin(2 * pi * f * t) * exp(-t * 3);
    },
  );

  // 5. Victory / Celebration fanfare
  generateWav(
    path: 'assets/sounds/victory.wav',
    durationSeconds: 1.2,
    sampleRate: 22050,
    generator: (t) {
      double f;
      if (t < 0.25) {
        f = 523.25; // C5
      } else if (t < 0.5) {
        f = 659.25; // E5
      } else if (t < 0.75) {
        f = 783.99; // G5
      } else {
        f = 1046.50; // C6
      }
      return sin(2 * pi * f * t) * exp(-(t % 0.25) * 4);
    },
  );

  print('All sound WAV files generated successfully in assets/sounds/');
}

void generateWav({
  required String path,
  required double durationSeconds,
  required int sampleRate,
  required double Function(double t) generator,
}) {
  final numSamples = (durationSeconds * sampleRate).toInt();
  final byteRate = sampleRate * 2; // 16-bit mono = 2 bytes per sample
  final dataSize = numSamples * 2;
  final totalSize = 36 + dataSize;

  final bytes = BytesBuilder();

  // RIFF header
  bytes.add('RIFF'.codeUnits);
  final headerData = ByteData(4)..setUint32(0, totalSize, Endian.little);
  bytes.add(headerData.buffer.asUint8List());
  bytes.add('WAVE'.codeUnits);

  // fmt chunk
  bytes.add('fmt '.codeUnits);
  final fmtChunkSize = ByteData(4)..setUint32(0, 16, Endian.little);
  bytes.add(fmtChunkSize.buffer.asUint8List());

  final fmtData = ByteData(16)
    ..setUint16(0, 1, Endian.little) // PCM
    ..setUint16(2, 1, Endian.little) // Mono
    ..setUint32(4, sampleRate, Endian.little)
    ..setUint32(8, byteRate, Endian.little)
    ..setUint16(12, 2, Endian.little) // block align
    ..setUint16(14, 16, Endian.little); // 16-bit
  bytes.add(fmtData.buffer.asUint8List());

  // data chunk
  bytes.add('data'.codeUnits);
  final dataChunkSize = ByteData(4)..setUint32(0, dataSize, Endian.little);
  bytes.add(dataChunkSize.buffer.asUint8List());

  final sampleData = ByteData(dataSize);
  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    var sample = generator(t);
    sample = sample.clamp(-1.0, 1.0);
    final intSample = (sample * 32767).toInt();
    sampleData.setInt16(i * 2, intSample, Endian.little);
  }
  bytes.add(sampleData.buffer.asUint8List());

  File(path).writeAsBytesSync(bytes.toBytes());
}
