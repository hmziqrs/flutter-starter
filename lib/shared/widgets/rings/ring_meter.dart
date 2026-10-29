import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// A value (0-1) as an arc on a track, in the ring gauge's language: the
/// track in the border color, the arc in the accent, both with round caps,
/// starting from the top.
///
/// Rings are only the line plus one orange accent, so the value reads as a
/// number elsewhere; pass [RingMeter.semanticsLabel] to announce it.
/// Decorative on its own.
class RingMeter extends StatelessWidget {
  const RingMeter({
    required this.value,
    this.size = 36,
    this.strokeWidth,
    this.color,
    this.trackColor,
    this.semanticsLabel,
    super.key,
  });

  /// The value to show, clamped into 0-1.
  final double value;

  /// Square side of the meter; the stroke and radius scale with it.
  final double size;

  /// Stroke width; defaults to the gauge's ratio (5 at 72).
  final double? strokeWidth;

  /// The arc's color; defaults to the theme's primary.
  final Color? color;

  /// The track's color; defaults to the theme's border.
  final Color? trackColor;

  /// What the meter says, for screen readers.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    Widget meter = CustomPaint(
      size: Size.square(size),
      painter: RingMeterPainter(
        share: value.clamp(0.0, 1.0),
        strokeWidth: strokeWidth ?? size * (5 / 72),
        arcColor: color ?? theme.colors.primary,
        trackColor: trackColor ?? theme.colors.border,
      ),
    );
    final label = semanticsLabel;
    if (label != null) {
      meter = Semantics(label: label, value: '$value', child: meter);
    } else {
      meter = ExcludeSemantics(child: meter);
    }
    return meter;
  }
}

/// Paints the meter: a full border-colored track and the accent arc of
/// [share], starting from the top with round caps.
class RingMeterPainter extends CustomPainter {
  RingMeterPainter({
    required this.share,
    required this.strokeWidth,
    required this.arcColor,
    required this.trackColor,
  });

  /// The drawn share, 0-1.
  final double share;

  final double strokeWidth;

  final Color arcColor;

  final Color trackColor;

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
    if (share <= 0) {
      return;
    }
    canvas.drawArc(
      rect,
      -90 * math.pi / 180,
      share * 2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = arcColor,
    );
  }

  @override
  bool shouldRepaint(RingMeterPainter oldDelegate) =>
      share != oldDelegate.share ||
      strokeWidth != oldDelegate.strokeWidth ||
      arcColor != oldDelegate.arcColor ||
      trackColor != oldDelegate.trackColor;
}
