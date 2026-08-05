import 'package:flutter_test/flutter_test.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:starter/features/feedback/shake_feedback_trigger.dart';

AccelerometerEvent _event(double x, double y, double z) {
  return AccelerometerEvent(x, y, z, DateTime.utc(2026));
}

void main() {
  group('magnitudeOf', () {
    test('gravity alone reads ~9.8', () {
      expect(magnitudeOf(_event(0, 0, 9.8)), closeTo(9.8, 0.001));
    });

    test('deliberate shake reads well above the threshold', () {
      expect(magnitudeOf(_event(10, 12, -15)), closeTo(21.66, 0.01));
    });
  });

  group('ShakeDetector', () {
    test('fires onShake when magnitude crosses the threshold', () {
      var shakes = 0;
      final detector = ShakeDetector(
        onShake: ({required magnitude}) => shakes += 1,
        debounce: const Duration(milliseconds: 10),
      );
      expect(shakes, 0);

      detector.handle(_event(0, 0, 9.8));
      expect(shakes, 0);

      detector.handle(_event(10, 12, -15));
      expect(shakes, 1);
    });

    test('debounce suppresses a second fire inside the window', () {
      var now = DateTime.utc(2026);
      var shakes = 0;
      final detector = ShakeDetector(
        onShake: ({required magnitude}) => shakes += 1,
        debounce: const Duration(seconds: 1),
        now: () => now,
      );
      expect(shakes, 0);

      detector.handle(_event(20, 0, 0));
      expect(shakes, 1);

      now = now.add(const Duration(milliseconds: 500));
      detector.handle(_event(20, 0, 0));
      expect(shakes, 1);

      now = now.add(const Duration(milliseconds: 600));
      detector.handle(_event(20, 0, 0));
      expect(shakes, 2);
    });

    test('custom magnitude threshold gates weaker gestures', () {
      var shakes = 0;
      final detector = ShakeDetector(
        onShake: ({required magnitude}) => shakes += 1,
        magnitudeThreshold: 25,
        debounce: const Duration(milliseconds: 10),
      );
      expect(shakes, 0);

      detector.handle(_event(10, 12, -15));
      expect(shakes, 0);

      detector.handle(_event(20, 20, -20));
      expect(shakes, 1);
    });

    test('reset clears the debounce timestamp', () {
      var now = DateTime.utc(2026);
      var shakes = 0;
      final detector = ShakeDetector(
        onShake: ({required magnitude}) => shakes += 1,
        debounce: const Duration(seconds: 10),
        now: () => now,
      );
      expect(shakes, 0);

      detector.handle(_event(20, 0, 0));
      expect(shakes, 1);

      now = now.add(const Duration(seconds: 1));
      detector.handle(_event(20, 0, 0));
      expect(shakes, 1);

      detector.reset();
      // ignore: cascade_invocations, reset and post-reset feed stay separate steps
      detector.handle(_event(20, 0, 0));
      expect(shakes, 2);
    });

    test('onShake receives the computed magnitude', () {
      double? received;
      final detector = ShakeDetector(
        onShake: ({required magnitude}) => received = magnitude,
        debounce: const Duration(milliseconds: 10),
      );
      expect(received, isNull);
      detector.handle(_event(10, 12, -15));
      expect(received, closeTo(21.66, 0.01));
    });
  });

  group('defaultStreamFactory', () {
    test('is a function reference (does not throw at lookup)', () {
      expect(defaultStreamFactory, isA<Function>());
    });
  });
}
