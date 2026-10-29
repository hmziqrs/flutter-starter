import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// The brand ring gauge (BRAND.md s7): a 72px ring at stroke 5, radius 30,
/// starting from the top with round caps, beside a value and its label.
///
/// With [share] (0–1) the ring draws a border-colored track and a primary arc
/// of that share. With [count] (n > 1) it draws n primary segments with
/// 5-unit gaps; when both are given, [count] wins. Rings are only the line
/// plus one orange accent, so the value and label stay in the normal text
/// colors.
class AppRingGauge extends StatelessWidget {
  const AppRingGauge({
    required this.value,
    required this.label,
    this.share,
    this.count,
    super.key,
  });

  static const double _diameter = 72;
  static const double _radius = 30;
  static const double _strokeWidth = 5;

  final double? share;

  final int? count;

  final String value;

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          width: _diameter,
          height: _diameter,
          child: CustomPaint(
            painter: _RingGaugePainter(
              trackColor: theme.colors.border,
              accentColor: theme.colors.primary,
              share: share,
              count: count,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              value,
              // App type scale, big stat: 24 w500 tight (display.xl).
              style: theme.typography.display.xl.copyWith(
                color: theme.colors.foreground,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.02 * (theme.typography.display.xl.fontSize ?? 24),
              ),
            ),
            Text(
              label,
              style: theme.typography.body.sm.copyWith(color: theme.colors.mutedForeground),
            ),
          ],
        ),
      ],
    );
  }
}

/// The gauge's accent arcs as (start degrees, sweep degrees) pairs, clockwise
/// from the top, over a full border-colored track.
@visibleForTesting
List<(double, double)> ringGaugeArcs({double? share, int? count}) {
  const startDegrees = -90.0;
  const fullTurnDegrees = 360.0;
  const gapUnits = 5.0;
  const radius = AppRingGauge._radius;

  final segments = count;
  if (segments != null && segments > 1) {
    const gapDegrees = gapUnits / radius * 180 / math.pi;
    final usable = fullTurnDegrees - gapDegrees * (segments - 1);
    if (usable <= 0) {
      return const <(double, double)>[];
    }
    final sweep = usable / segments;
    return <(double, double)>[
      for (var index = 0; index < segments; index++)
        (startDegrees + index * (sweep + gapDegrees), sweep),
    ];
  }
  final resolvedShare = math.min(math.max(share ?? 1, 0), 1).toDouble();
  return <(double, double)>[(startDegrees, resolvedShare * fullTurnDegrees)];
}

class _RingGaugePainter extends CustomPainter {
  _RingGaugePainter({
    required this.trackColor,
    required this.accentColor,
    required this.share,
    required this.count,
  });

  final Color trackColor;
  final Color accentColor;
  final double? share;
  final int? count;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final rect = Rect.fromCircle(center: center, radius: AppRingGauge._radius);
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppRingGauge._strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    final accentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppRingGauge._strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = accentColor;

    canvas.drawCircle(center, AppRingGauge._radius, trackPaint);
    for (final (start, sweep) in ringGaugeArcs(share: share, count: count)) {
      canvas.drawArc(rect, start * math.pi / 180, sweep * math.pi / 180, false, accentPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingGaugePainter old) =>
      trackColor != old.trackColor ||
      accentColor != old.accentColor ||
      share != old.share ||
      count != old.count;
}
