import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

final class ShakeDetector {
  ShakeDetector({
    required this.onShake,
    this.magnitudeThreshold = _shakeMagnitudeThreshold,
    this.debounce = _shakeDebounce,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final ShakeCallback onShake;

  final double magnitudeThreshold;

  final Duration debounce;

  final DateTime Function() _now;
  DateTime? _lastFire;

  void handle(AccelerometerEvent event) {
    final magnitude = magnitudeOf(event);
    if (magnitude < magnitudeThreshold) return;
    final now = _now();
    final lastFire = _lastFire;
    if (lastFire != null && now.difference(lastFire) < debounce) return;
    _lastFire = now;
    onShake(magnitude: magnitude);
  }

  void reset() => _lastFire = null;
}

double magnitudeOf(AccelerometerEvent event) {
  return math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
}

typedef ShakeStreamFactory =
    Stream<AccelerometerEvent> Function({
      required Duration samplingPeriod,
    });

typedef ShakeCallback = void Function({required double magnitude});

const double _shakeMagnitudeThreshold = 18;

const Duration _shakeDebounce = Duration(milliseconds: 900);

const Duration _shakeSamplingPeriod = SensorInterval.gameInterval;

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

  final bool enabled;

  final ShakeCallback onShake;

  final Widget child;

  final ShakeStreamFactory streamFactory;

  final double magnitudeThreshold;

  final Duration debounce;

  @override
  State<ShakeFeedbackTrigger> createState() => _ShakeFeedbackTriggerState();
}

class _ShakeFeedbackTriggerState extends State<ShakeFeedbackTrigger> {
  StreamSubscription<AccelerometerEvent>? _subscription;
  late ShakeDetector _detector;

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
      _sensorAvailable = false;
      return;
    }
    _subscription = stream.listen(
      _detector.handle,
      onError: (_) {
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

@pragma('vm:entry-point')
Stream<AccelerometerEvent> defaultStreamFactory({required Duration samplingPeriod}) {
  return accelerometerEventStream(samplingPeriod: samplingPeriod);
}
