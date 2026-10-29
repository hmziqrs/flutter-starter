import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/brand_tokens.dart';

/// One share of a [RingMeter]: a name, its value 0-1, and an optional detail
/// line under the name.
@immutable
final class RingMeterItem {
  const RingMeterItem({required this.label, required this.value, this.detail});

  final String label;

  /// The share of the ring this item draws, clamped into 0-1.
  final double value;

  /// Small muted line under the label, e.g. "7.2 of 10 GB".
  final String? detail;

  @override
  bool operator ==(Object other) =>
      other is RingMeterItem &&
      label == other.label &&
      value == other.value &&
      detail == other.detail;

  @override
  int get hashCode => Object.hash(label, value, detail);
}

/// Several shares at once, as rings inside rings (the kits' `ring-meter`):
/// up to four concentric rings, the first in the accent, the rest in the
/// text color at falling strengths (85%, 55%, 35%), each drawn from the top
/// on a faint hairline track. The legend beside it names every share.
///
/// Rings are only the line plus one orange accent, so the first item carries
/// the accent. Pass [RingMeter.semanticsLabel] to name the rings for screen
/// readers; the legend text is always readable.
class RingMeter extends StatelessWidget {
  const RingMeter({
    required this.items,
    required this.label,
    this.size = 168,
    this.semanticsLabel,
    super.key,
  });

  /// The shares to show; the first four draw, the rest are ignored, like the
  /// kit's `items.slice(0, 4)`.
  final List<RingMeterItem> items;

  /// What the rings show, e.g. "Usage this month"; heads the legend.
  final String label;

  /// Square side of the rings.
  final double size;

  /// What the rings say for screen readers; defaults to the kit's summary,
  /// "Usage this month: Storage 72%, Build minutes 40%".
  final String? semanticsLabel;

  /// The text color strengths of the non-accent rings, outermost first
  /// (`strengths` in ring-meter.svelte).
  static const List<double> _strengths = <double>[1, 0.85, 0.55, 0.35];

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final shown = items.take(4).toList();
    final rings = <(double, Color)>[
      for (final (index, item) in shown.indexed)
        (
          item.value.clamp(0.0, 1.0),
          index == 0
              ? theme.colors.primary
              : theme.colors.foreground.withValues(alpha: _strengths[index]),
        ),
    ];
    final announced =
        semanticsLabel ??
        '$label: ${[
          for (final item in shown) '${item.label} ${_percent(item.value)}',
        ].join(", ")}';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          label: announced,
          image: true,
          child: ExcludeSemantics(
            child: CustomPaint(
              size: Size.square(size),
              painter: RingMeterPainter(
                values: <double>[for (final (value, _) in rings) value],
                colors: <Color>[for (final (_, color) in rings) color],
                trackColor: theme.brand.line,
              ),
            ),
          ),
        ),
        const SizedBox(width: 32),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: theme.typography.body.sm.copyWith(
                  color: theme.colors.foreground,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              for (final (index, item) in shown.indexed) ...<Widget>[
                if (index > 0) const SizedBox(height: 10),
                _LegendRow(item: item, color: rings[index].$2, theme: theme),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// The kit's percent: `Math.round(v * 100)` of the clamped value.
  static String _percent(double value) => '${(value.clamp(0.0, 1.0) * 100).round()}%';
}

/// One legend row: the ring's color as a dot, the name with its detail line,
/// and the percent.
class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.item,
    required this.color,
    required this.theme,
  });

  final RingMeterItem item;

  final Color color;

  final FThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                item.label,
                style: theme.typography.body.sm.copyWith(
                  color: theme.colors.foreground,
                ),
              ),
              if (item.detail != null)
                Text(
                  item.detail!,
                  style: theme.typography.body.xs.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          RingMeter._percent(item.value),
          style: theme.typography.body.sm.copyWith(
            color: theme.colors.foreground,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Paints the meter's rings in the kit's 100x100 viewBox: ring *i* at radius
/// `44 - 9 * i`, a full hairline track at 60% and the value arc from the top
/// (the kit's `rotate(-90)`), both stroke 5 with round caps on the arc.
class RingMeterPainter extends CustomPainter {
  RingMeterPainter({
    required this.values,
    required this.colors,
    required this.trackColor,
  }) : assert(
         values.length == colors.length,
         'every drawn share needs its color',
       ),
       assert(values.length <= 4, 'the kit draws at most four rings');

  /// The shares to draw, 0-1 each, outermost first.
  final List<double> values;

  /// The arc colors, outermost first.
  final List<Color> colors;

  /// The tracks' color, drawn at the kit's 60% opacity.
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 100;
    final center = size.center(Offset.zero);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5 * scale
      ..color = trackColor.withValues(alpha: trackColor.a * 0.6);
    for (final (index, value) in values.indexed) {
      final radius = (44 - 9 * index) * scale;
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawCircle(center, radius, track);
      if (value <= 0) {
        continue;
      }
      canvas.drawArc(
        rect,
        -90 * math.pi / 180,
        value * 2 * math.pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5 * scale
          ..strokeCap = StrokeCap.round
          ..color = colors[index],
      );
    }
  }

  @override
  bool shouldRepaint(RingMeterPainter oldDelegate) =>
      values != oldDelegate.values ||
      colors != oldDelegate.colors ||
      trackColor != oldDelegate.trackColor;
}
