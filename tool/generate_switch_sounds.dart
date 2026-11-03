import 'dart:math';

import 'generate_sounds.dart' show generateWav;

void main() {
  for (final enabled in [true, false]) {
    generateWav(
      path: 'assets/sounds/switch_${enabled ? 'on' : 'off'}.wav',
      durationSeconds: .13,
      sampleRate: 22050,
      generator: (t) {
        final phase = t < .055 ? 0 : 1;
        final local = phase == 0 ? t : t - .055;
        final frequency = enabled
            ? (phase == 0 ? 493.88 : 659.25)
            : (phase == 0 ? 493.88 : 392.00);
        final envelope = sin(pi * min(1.0, local / .006)) *
            exp(-local * (phase == 0 ? 38 : 26));
        return .35 * envelope * sin(2 * pi * frequency * t);
      },
    );
  }
}
