import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// The brand ring gauge (BRAND.md s7): a 72px ring at stroke 5, radius 30,
/// starting from the top with round caps, beside a value and its label.
///
/// With [share] (0–1) the ring draws a border-colored track and a primary arc
/// of that share, round-capped. With [count] (n > 1) it draws n primary
/// segments with 5-unit gaps and square ends and no track — the brand's
/// `c / n - 5` dash recipe, so a gap also wraps past the starting point.
/// When both are given, [count] wins. Rings are only the line plus one orange
/// accent, so the value and label stay in the normal text colors.
class AppRingGauge extends StatelessWidget {
  const AppRingGauge({
    required this.value,
    required this.label,
    this.share,
    this.count,
    this.spacing = 16,
    super.key,
  });

  static const double _diameter = 72;
  static const double _radius = 30;
  static const double _strokeWidth = 5;

  /// Gap between the value and its label: the brand's `flex-col gap-1`.
  static const double _labelGap = 4;

  final double? share;

  final int? count;

  final String value;

  final String label;

  /// Space between the ring and the text. The brand gauge story sets `gap-4`
  /// (16, the default); the ring-stats block sits tighter at `gap-4.5` (18).
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    // The gauge's own number recipe (BRAND.md s7, ring-stats.svelte:24):
    // `text-[1.75rem] leading-[1.05] font-medium tracking-[-0.03em]` — 28px
    // at a 1.05 line height. Sized as 28/24 of the display.xl token so it
    // rides the theme's display scale (24 at the default); StatCard's 24/-0.02
    // big stat is a different piece.
    final numberFontSize = (theme.typography.display.xl.fontSize ?? 24) * 28 / 24;
    final numberStyle = theme.typography.display.xl.copyWith(
      fontSize: numberFontSize,
      color: theme.colors.foreground,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.03 * numberFontSize,
      height: 1.05,
    );
    final texts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(value, style: numberStyle),
        const SizedBox(height: _labelGap),
        Text(
          label,
          style: theme.typography.body.sm.copyWith(color: theme.colors.mutedForeground),
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) => Row(
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
          SizedBox(width: spacing),
          // In a bounded slot (a ring-stats cell) the brand's text spans wrap
          // inside the grid cell, so the column takes the remaining width and
          // long labels fold. Unbounded parents (a Wrap) keep the min layout.
          if (constraints.maxWidth.isFinite) Expanded(child: texts) else texts,
        ],
      ),
    );
  }
}

/// The gauge's accent arcs as (start degrees, sweep degrees) pairs, clockwise
/// from the top. The share form draws over a full border-colored track; the
/// count form's arcs are the brand's dash recipe — each a 5-unit gap shorter
/// than its nth of the circle, with the closing gap wrapping past the top.
@visibleForTesting
List<(double, double)> ringGaugeArcs({double? share, int? count}) {
  const startDegrees = -90.0;
  const fullTurnDegrees = 360.0;
  const gapUnits = 5.0;
  const radius = AppRingGauge._radius;

  final segments = count;
  if (segments != null && segments > 1) {
    const gapDegrees = gapUnits / radius * 180 / math.pi;
    // SVG clamps a negative dash to nothing; keep extreme counts sane too.
    final sweep = math.max<double>(fullTurnDegrees / segments - gapDegrees, 0);
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
    final arcs = ringGaugeArcs(share: share, count: count);
    // Segmented mode stands alone on the accent color with square ends, the
    // brand SVG's single dasharray circle; the share mode rides a track.
    final segmented = count != null && count! > 1;
    if (!segmented) {
      canvas.drawCircle(
        center,
        AppRingGauge._radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = AppRingGauge._strokeWidth
          ..strokeCap = StrokeCap.round
          ..color = trackColor,
      );
    }
    final accentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppRingGauge._strokeWidth
      ..strokeCap = segmented ? StrokeCap.butt : StrokeCap.round
      ..color = accentColor;
    for (final (start, sweep) in arcs) {
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
