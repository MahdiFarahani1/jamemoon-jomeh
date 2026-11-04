import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/hot_potato/presentation/cubit/hot_potato_cubit.dart';

void main() {
  test('bomb ticks keep a steady minimum spacing until the fuse ends', () {
    for (final durationMs in [18000, 25000, 38000]) {
      final schedule = BombPulseSchedule();
      final pulses = <int>[];
      for (var elapsed = 0; elapsed < durationMs; elapsed += 100) {
        if (schedule.shouldPulse(elapsed, elapsed / durationMs)) {
          pulses.add(elapsed);
        }
      }
      for (var i = 1; i < pulses.length; i++) {
        expect(pulses[i] - pulses[i - 1], inInclusiveRange(250, 900));
      }
      expect(durationMs - pulses.last, lessThanOrEqualTo(500));
      schedule.reset();
      expect(schedule.shouldPulse(0, 0), isTrue);
    }
  });
}
