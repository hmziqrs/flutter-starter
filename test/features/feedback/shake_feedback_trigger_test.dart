import 'package:flutter_test/flutter_test.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:starter/features/feedback/shake_feedback_trigger.dart';

AccelerometerEvent _event(double x, double y, double z) {
  // AccelerometerEvent requires a timestamp and is not const-constructible.
  return AccelerometerEvent(x, y, z, DateTime.utc(2026));
}

void main() {
  group('magnitudeOf', () {
    test('gravity alone reads ~9.8', () {
      expect(magnitudeOf(_event(0, 0, 9.8)), closeTo(9.8, 0.001));
    });

    test('deliberate shake reads well above the threshold', () {
      // sqrt(100 + 144 + 225) = sqrt(469) ~ 21.66
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

      // Sub-threshold (gravity alone) does not fire.
      detector.handle(_event(0, 0, 9.8));
      expect(shakes, 0);

      // Deliberate shake fires once.
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

      // 500ms later — still inside the 1s window — a second shake is suppressed.
      now = now.add(const Duration(milliseconds: 500));
      detector.handle(_event(20, 0, 0));
      expect(shakes, 1);

      // Past the window — the next shake fires.
      now = now.add(const Duration(milliseconds: 600));
      detector.handle(_event(20, 0, 0));
      expect(shakes, 2);
    });

    test('custom magnitude threshold gates weaker gestures', () {
      var shakes = 0;
      final detector = ShakeDetector(
        onShake: ({required magnitude}) => shakes += 1,
        magnitudeThreshold: 25, // higher than the default 18
        debounce: const Duration(milliseconds: 10),
      );
      expect(shakes, 0);

      // Magnitude ~21.66 — below the custom threshold.
      detector.handle(_event(10, 12, -15));
      expect(shakes, 0);

      // Magnitude ~34.64 — above the custom threshold.
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

      // Inside the window — suppressed.
      now = now.add(const Duration(seconds: 1));
      detector.handle(_event(20, 0, 0));
      expect(shakes, 1);

      // Reset clears the window — the next shake fires immediately.
      detector.reset();
      // Cascade would read `..reset()..handle(..)` but we want the reset to be
      // a distinct, observable step before the post-reset feed.
      // ignore: cascade_invocations
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
      // The production factory is the single seam to sensors_plus. Referencing
      // it must not throw on platforms without an accelerometer at lookup time
      // — the trigger guards the call itself.
      expect(defaultStreamFactory, isA<Function>());
    });
  });
}
