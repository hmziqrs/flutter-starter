import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/brand_tokens.dart';
import 'package:starter/shared/widgets/rings/brand_rings.dart';
import 'package:starter/shared/widgets/rings/brand_seed.dart';

/// The band arcs recipe (BRAND.md s7): 8 rings around (400, 200) in a
/// 400x400 picture, radius `60 + 44 * i`, ring 3 in the accent at width 3
/// with a 60% gap, the rest in the line at width 1.25 with a 20% gap, every
/// ring turned `150 + 23 * i` degrees. The same on every site — no seed.
List<RingArc> bandArcsRecipe() => <RingArc>[
  for (var i = 0; i < 8; i += 1)
    () {
      final radius = 60.0 + 44 * i;
      final circumference = 2 * math.pi * radius;
      final gap = circumference * (i == 3 ? 0.6 : 0.2);
      return RingArc(
        radius: radius,
        drawn: round2(circumference - gap),
        gap: round2(gap),
        rotateDegrees: (150 + 23 * i).toDouble(),
        accent: i == 3,
      );
    }(),
];

/// Big arcs on the right of a closing band, full height and bleeding off the
/// edge.
///
/// The same on every site. On the orange band pass the band's own accent —
/// the on-orange color — so ring 3 reads dark on the orange, like the web's
/// band redefining its tokens. Decorative: excluded from semantics.
class BandArcs extends StatelessWidget {
  const BandArcs({this.accentColor, this.size = 400, super.key});

  /// The accent ring's color; defaults to the theme's primary.
  final Color? accentColor;

  /// Square side of the picture.
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: RingPicturePainter(
            arcs: bandArcsRecipe(),
            center: const Offset(400, 200),
            viewBox: const Size(400, 400),
            lineWidth: 1.25,
            accentWidth: 3,
            dotRadius: 0,
            lineColor: theme.brand.line,
            accentColor: accentColor ?? theme.colors.primary,
          ),
        ),
      ),
    );
  }
}
