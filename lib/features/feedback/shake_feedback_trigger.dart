import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Pure-Dart shake detector over a stream of `AccelerometerEvent`s. Extracted
/// from [ShakeFeedbackTrigger] so the threshold + debounce math is unit-testable
/// without pumping a widget (the lifecycle glue stays in the widget). Stateless
/// except for the debounce timestamp; safe to drive from a single subscription.
final class ShakeDetector {
  ShakeDetector({
    required this.onShake,
    this.magnitudeThreshold = _shakeMagnitudeThreshold,
    this.debounce = _shakeDebounce,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final ShakeCallback onShake;

  /// Per-sample magnitude threshold. Tuned for a deliberate gesture.
  final double magnitudeThreshold;

  /// Minimum gap between consecutive shake fires.
  final Duration debounce;

  final DateTime Function() _now;
  DateTime? _lastFire;

  /// Feeds one accelerometer reading. Call from the stream listener. Fires
  /// [onShake] when the magnitude crosses [magnitudeThreshold] and the debounce
  /// window has elapsed since the last fire.
  void handle(AccelerometerEvent event) {
    final magnitude = magnitudeOf(event);
    if (magnitude < magnitudeThreshold) return;
    final now = _now();
    final lastFire = _lastFire;
    if (lastFire != null && now.difference(lastFire) < debounce) return;
    _lastFire = now;
    onShake(magnitude: magnitude);
  }

  /// Resets the internal debounce timestamp (e.g. on re-enable).
  void reset() => _lastFire = null;
}

/// Computes the magnitude (m/s²) of an accelerometer reading: the sqrt of the
/// squared-sum of the three axes. Top-level so tests + the detector share it.
double magnitudeOf(AccelerometerEvent event) {
  return math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
}

/// Detects accelerometer shakes and fires the mounted [ShakeCallback]. Mounted
/// by `_AppViewState` only when the platform has an accelerometer AND the user
/// opted into the `feedback.shake_enabled` setting (feedback spec — shake is
/// divisive + platform-gated). Desktop / web platforms have no accelerometer;
/// the default stream factory throws `MissingPluginException` there, which the
/// trigger swallows and disables itself honestly (never fakes a shake).
///
/// **Feature-local** (feedback spec audit §3: single consumer — keep here
/// until a second caller arrives, then promote to `lib/shared/widgets/`).
///
/// The plugin is never called from a widget method directly (HARD RULE 4):
/// `streamFactory` is the single seam, and tests inject a fake factory driven
/// by a `StreamController<AccelerometerEvent>`. Production passes
/// [defaultStreamFactory].
typedef ShakeStreamFactory =
    Stream<AccelerometerEvent> Function({
      required Duration samplingPeriod,
    });

/// Signature of a shake callback. Receives the magnitude (m/s², sqrt of the
/// squared-sum of the three axes) so a caller can log / gate further.
typedef ShakeCallback = void Function({required double magnitude});

/// Threshold (m/s²) above which a single accelerometer reading counts as a
/// shake. Gravity alone reads ~9.8; a deliberate shake spikes well past this.
/// Tuned for a deliberate gesture — a casual carry does not fire.
const double _shakeMagnitudeThreshold = 18;

/// Minimum gap between consecutive shake fires so one gesture does not fan out
/// into many sheet opens. The debounce starts at the last fire, not the last
/// sample.
const Duration _shakeDebounce = Duration(milliseconds: 900);

/// Sampling period for the accelerometer stream (a power / accuracy trade-off
/// — `Game` reads ~20ms which is responsive enough for a deliberate gesture
/// without burning battery).
const Duration _shakeSamplingPeriod = SensorInterval.gameInterval;

/// Wraps [child] with a shake detector that fires [onShake] on a deliberate
/// device shake. The detector subscribes to the accelerometer stream only
/// while [enabled] is true (so the opt-in toggle + platform gate can turn it
/// off at runtime); the subscription is cancelled on dispose and whenever
/// [enabled] flips to false.
///
/// Motion guard (feedback spec audit §5): shake detection is a sensor input,
/// not a visual animation, so `MediaQuery.disableAnimationsOf` does not gate
/// it — the user-facing motion is the sheet's ForUI slide, which IS guarded by
/// `FThemeMotion` + the navigation-never-gates rule. The detector is a
/// pure-Dart signal path with no visual animation of its own.
class ShakeFeedbackTrigger extends StatefulWidget {
  const ShakeFeedbackTrigger({
    required this.enabled,
    required this.onShake,
    required this.child,
    this.streamFactory = defaultStreamFactory,
    this.magnitudeThreshold = _shakeMagnitudeThreshold,
    this.debounce = _shakeDebounce,
    super.key,
  });

  /// `false` disables the detector (no subscription). Wire to the
  /// `feedbackShakeEnabledControllerProvider` value AND'd with
  /// `PlatformCapabilities` (web / desktop have no accelerometer).
  final bool enabled;

  /// Fired on a detected shake. The caller opens the feedback sheet.
  final ShakeCallback onShake;

  /// The UI this detector wraps. Built exactly once.
  final Widget child;

  /// Source of accelerometer events. Production uses
  /// [defaultStreamFactory] (sensors_plus); tests inject a fake driven by a
  /// `StreamController<AccelerometerEvent>`.
  final ShakeStreamFactory streamFactory;

  /// Per-sample magnitude threshold. Exposed for tests so a fixture gesture
  /// can cross it deterministically.
  final double magnitudeThreshold;

  /// Minimum gap between fires. Exposed for tests so the debounce window can
  /// be asserted under `FakeAsync`.
  final Duration debounce;

  @override
  State<ShakeFeedbackTrigger> createState() => _ShakeFeedbackTriggerState();
}

class _ShakeFeedbackTriggerState extends State<ShakeFeedbackTrigger> {
  StreamSubscription<AccelerometerEvent>? _subscription;
  late ShakeDetector _detector;
  // Whether the platform actually exposed a live accelerometer stream. Flipped
  // false if the factory throws (web / desktop) so the trigger degrades
  // honestly rather than crashing.
  bool _sensorAvailable = true;

  @override
  void initState() {
    super.initState();
    _detector = ShakeDetector(
      onShake: widget.onShake,
      magnitudeThreshold: widget.magnitudeThreshold,
      debounce: widget.debounce,
    );
    if (widget.enabled) {
      _start();
    }
  }

  @override
  void didUpdateWidget(covariant ShakeFeedbackTrigger oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onShake != oldWidget.onShake ||
        widget.magnitudeThreshold != oldWidget.magnitudeThreshold ||
        widget.debounce != oldWidget.debounce) {
      _detector = ShakeDetector(
        onShake: widget.onShake,
        magnitudeThreshold: widget.magnitudeThreshold,
        debounce: widget.debounce,
      );
    }
    if (oldWidget.enabled != widget.enabled) {
      widget.enabled ? _start() : _stop();
    }
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  void _start() {
    if (!_sensorAvailable) return;
    _stop();
    Stream<AccelerometerEvent> stream;
    try {
      stream = widget.streamFactory(samplingPeriod: _shakeSamplingPeriod);
    } on Object {
      // sensors_plus throws on platforms without an accelerometer (web /
      // desktop). Disable honestly — never fake a shake.
      _sensorAvailable = false;
      return;
    }
    _subscription = stream.listen(
      _detector.handle,
      onError: (_) {
        // A stream error mid-flight (sensor detached) disables further
        // detection rather than surfacing an error to the UI.
        _sensorAvailable = false;
      },
    );
  }

  void _stop() {
    unawaited(_subscription?.cancel());
    _subscription = null;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Production stream factory backed by `sensors_plus`. Throws on platforms
/// without an accelerometer (web / desktop); the trigger swallows that and
/// disables itself honestly. Kept as a top-level function so it is the single
/// seam between the feature and the plugin (HARD RULE 4 — no widget calls a
/// plugin directly; the factory does).
@pragma('vm:entry-point')
Stream<AccelerometerEvent> defaultStreamFactory({required Duration samplingPeriod}) {
  return accelerometerEventStream(samplingPeriod: samplingPeriod);
}
