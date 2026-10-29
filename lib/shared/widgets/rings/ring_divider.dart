import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/brand_tokens.dart';
import 'package:starter/shared/widgets/rings/brand_seed.dart';

/// The kit's `ring-divider` recipe: three rings around (20, 20) in a 40x40
/// picture, radius [6, 11, 16], drawn from [seed] with `hash(seed) + 13`.
/// The accent is ring `1 + floor(r() * 2)` with a 50% gap and a dot of
/// radius 1.9 where it ends; the rest gap 15-45%.
List<RingArc> ringDividerArcs(String seed) {
  final hash = hashName(seed);
  final random = SeededRandom(hash + 13);
  final accent = 1 + random.nextIndex(2);
  return seedArcs(
    random,
    cx: 20,
    cy: 20,
    radii: const <double>[6, 11, 16],
    accent: accent,
    accentGap: 0.5,
    gapRange: (0.15, 0.3),
  );
}

/// A break between sections (the kits' `ring-divider`): a hairline that
/// meets a small set of seeded rings, drawn from [seed]. Pass [label] for a
/// chapter mark between the hairlines; [alignStart] keeps only the trailing
/// hairline, for the start of a run.
///
/// The accent ring's dot reads hollow at rest and fills when [filled] marks
/// something on, open, done or selected — the brand marker's rule. Rings are
/// only the line plus one orange accent. Decorative: pair it with a heading
/// or label that carries the meaning.
class RingDivider extends StatelessWidget {
  const RingDivider({
    this.filled = false,
    this.accentColor,
    this.gap = 16,
    this.seed = 'divider',
    this.label,
    this.alignStart = false,
    super.key,
  });

  /// Fills the accent ring's end dot: on, open, done or selected.
  final bool filled;

  /// The accent's color; defaults to the theme's primary.
  final Color? accentColor;

  /// Space between the hairlines, the rings and the words; the kit's
  /// `gap-4`.
  final double gap;

  /// The name the rings are drawn from; the same name always draws the same
  /// picture.
  final String seed;

  /// Optional chapter words between the hairlines (the kit's children).
  final String? label;

  /// Keeps only the trailing hairline, so the divider starts at the edge.
  final bool alignStart;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Row(
      children: <Widget>[
        if (!alignStart) ...<Widget>[
          Expanded(
            child: Container(height: 1, color: theme.colors.border),
          ),
          SizedBox(width: gap),
        ],
        ExcludeSemantics(
          child: CustomPaint(
            // The kit shows the 40x40 picture at 28px (size-7).
            size: const Size.square(28),
            painter: _RingDividerPainter(
              arcs: ringDividerArcs(seed),
              lineWidth: 1.2,
              accentWidth: 1.8,
              dotRadius: 1.9,
              lineColor: theme.brand.line,
              accentColor: accentColor ?? theme.colors.primary,
              filled: filled,
            ),
          ),
        ),
        if (label != null) ...<Widget>[
          SizedBox(width: gap),
          Text(
            label!,
            style: theme.typography.body.sm.copyWith(color: theme.colors.mutedForeground),
          ),
        ],
        SizedBox(width: gap),
        Expanded(
          child: Container(height: 1, color: theme.colors.border),
        ),
      ],
    );
  }
}

/// Paints the divider's ring cluster in the kit's 40x40 viewBox: faint rings
/// at 1.2 and the accent at 1.8, round caps, and the accent ring's end dot —
/// solid when [filled], a hollow ring otherwise.
class _RingDividerPainter extends CustomPainter {
  const _RingDividerPainter({
    required this.arcs,
    required this.lineWidth,
    required this.accentWidth,
    required this.dotRadius,
    required this.lineColor,
    required this.accentColor,
    required this.filled,
  });

  final List<RingArc> arcs;

  final double lineWidth;

  final double accentWidth;

  final double dotRadius;

  final Color lineColor;

  final Color accentColor;

  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 40;
    final center = Offset(20 * scale, 20 * scale);
    for (final arc in arcs) {
      final radius = arc.radius * scale;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        arc.rotateDegrees * math.pi / 180,
        arc.drawn / arc.radius,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = (arc.accent ? accentWidth : lineWidth) * scale
          ..strokeCap = StrokeCap.round
          ..color = arc.accent ? accentColor : lineColor,
      );
      if (arc.accent) {
        final end = arc.end;
        if (end != null) {
          final dotCenter = Offset(end.dx * scale, end.dy * scale);
          final dotPaint = Paint()..color = accentColor;
          if (filled) {
            canvas.drawCircle(dotCenter, dotRadius * scale, dotPaint);
          } else {
            canvas.drawCircle(
              dotCenter,
              dotRadius * scale,
              dotPaint
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.4 * scale,
            );
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(_RingDividerPainter oldDelegate) =>
      arcs != oldDelegate.arcs ||
      lineColor != oldDelegate.lineColor ||
      accentColor != oldDelegate.accentColor ||
      filled != oldDelegate.filled;
}
