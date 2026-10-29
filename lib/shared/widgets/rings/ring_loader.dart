import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/brand_tokens.dart';

/// An indeterminate loader drawn in the rings' language: an accent arc
/// sweeping around a hairline track, round caps, from the top.
///
/// The sweep is the loader's still picture under reduced motion: a quarter
/// arc, no rotation. Pass [RingLoader.semanticsLabel] to announce it;
/// otherwise it announces the common "Loading" string.
class RingLoader extends StatefulWidget {
  const RingLoader({
    this.size = 24,
    this.strokeWidth,
    this.color,
    this.trackColor,
    this.semanticsLabel,
    super.key,
  });

  /// Square side of the loader.
  final double size;

  /// Stroke width; defaults to the loader's own ratio (2.5 at 24).
  final double? strokeWidth;

  /// The sweeping arc's color; defaults to the theme's primary.
  final Color? color;

  /// The track's color; defaults to the brand's ring-art hairline.
  final Color? trackColor;

  /// What the loader says, for screen readers.
  final String? semanticsLabel;

  @override
  State<RingLoader> createState() => _RingLoaderState();
}

class _RingLoaderState extends State<RingLoader> with SingleTickerProviderStateMixin {
  static const double _cycleSeconds = 1.2;

  Ticker? _ticker;

  final ValueNotifier<double> _elapsed = ValueNotifier<double>(0);

  bool _reducedMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    _syncTicker();
  }

  @override
  void didUpdateWidget(RingLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTicker();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _elapsed.dispose();
    super.dispose();
  }

  void _syncTicker() {
    if (_reducedMotion) {
      _ticker
        ?..stop()
        ..dispose();
      _ticker = null;
      if (_elapsed.value != 0) {
        _elapsed.value = 0;
      }
      return;
    }
    final ticker = _ticker ??= createTicker(_onTick);
    if (!ticker.isActive) {
      unawaited(ticker.start());
    }
  }

  void _onTick(Duration elapsed) {
    _elapsed.value = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Semantics(
      label: widget.semanticsLabel ?? context.t.common.loading,
      child: SizedBox.square(
        dimension: widget.size,
        child: CustomPaint(
          painter: RingLoaderPainter(
            strokeWidth: widget.strokeWidth ?? widget.size * (2.5 / 24),
            sweepColor: widget.color ?? theme.colors.primary,
            trackColor: widget.trackColor ?? theme.brand.line,
            elapsed: _elapsed,
            // Under reduced motion the notifier never fires: still picture.
            repaint: _elapsed,
          ),
        ),
      ),
    );
  }
}

/// Paints the loader: a full hairline track and the sweeping accent arc.
///
/// The arc's start rotates once per cycle while its sweep grows and shrinks,
/// so the head chases the tail. Under reduced motion the picture is still: a
/// quarter arc from the top.
class RingLoaderPainter extends CustomPainter {
  RingLoaderPainter({
    required this.strokeWidth,
    required this.sweepColor,
    required this.trackColor,
    ValueListenable<double>? elapsed,
    super.repaint,
  }) : _elapsed = elapsed ?? const _FixedElapsed(0);

  final double strokeWidth;

  final Color sweepColor;

  final Color trackColor;

  final ValueListenable<double> _elapsed;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);

    final elapsed = _elapsed.value;
    // The still picture: a quarter arc from the top.
    var startDegrees = -90.0;
    var sweepDegrees = 90.0;
    if (elapsed > 0) {
      final cycle = (elapsed / _RingLoaderState._cycleSeconds) % 1;
      startDegrees = -90 + 360 * cycle;
      final grow = Curves.easeInOut.transform((2 * cycle) % 1);
      sweepDegrees = 30 + 240 * grow;
    }
    canvas.drawArc(
      rect,
      startDegrees * math.pi / 180,
      sweepDegrees * math.pi / 180,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = sweepColor,
    );
  }

  @override
  bool shouldRepaint(RingLoaderPainter oldDelegate) =>
      strokeWidth != oldDelegate.strokeWidth ||
      sweepColor != oldDelegate.sweepColor ||
      trackColor != oldDelegate.trackColor;
}

final class _FixedElapsed implements ValueListenable<double> {
  const _FixedElapsed(this.value);

  @override
  final double value;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}
