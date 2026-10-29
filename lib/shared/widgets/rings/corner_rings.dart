import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/brand_tokens.dart';
import 'package:starter/shared/widgets/rings/brand_rings.dart';
import 'package:starter/shared/widgets/rings/brand_seed.dart';

/// The corner rings recipe (BRAND.md s7): 9 rings around (100, 0) in a
/// 100x100 picture, radius `11 + 11 * i`, drawn from [seed] with
/// `hash(seed) + 23`. The accent is ring `3 + hash(seed) % 3` with a 50% gap
/// and a dot of radius 1.8 where it ends; the rest gap 10-40%.
///
/// With [quiet]: 8 rings at radius `12 + 12 * i`, accent ring
/// `2 + hash(seed) % 3`, no dot — for cards that hold more text.
List<RingArc> cornerRingArcs(String seed, {bool quiet = false}) {
  final hash = hashName(seed);
  final random = SeededRandom(hash + (quiet ? 29 : 23));
  final accent = (quiet ? 2 : 3) + hash % 3;
  final arcs = seedArcs(
    random,
    cx: 100,
    cy: 0,
    radii: <double>[
      for (var i = 0; i < (quiet ? 8 : 9); i += 1) (quiet ? 12.0 : 11.0) + (quiet ? 12 : 11) * i,
    ],
    accent: accent,
    accentGap: 0.5,
    gapRange: (0.1, 0.3),
  );
  if (!quiet) {
    return arcs;
  }
  // The quiet variant never draws the dot, as on the web.
  return <RingArc>[
    for (final arc in arcs)
      RingArc(
        radius: arc.radius,
        drawn: arc.drawn,
        gap: arc.gap,
        rotateDegrees: arc.rotateDegrees,
        accent: arc.accent,
      ),
  ];
}

/// A card's fingerprint: faint rings in its top-right corner, one of them in
/// the card's kind color.
///
/// Place it first inside a clipped card and give the card's content the
/// higher z-order: rings are never drawn behind text (BRAND.md s13). The
/// same [CornerRings.seed] always draws the same picture. Decorative:
/// excluded from semantics.
class CornerRings extends StatelessWidget {
  const CornerRings({
    required this.seed,
    this.accentColor,
    this.quiet = false,
    this.size = 100,
    super.key,
  });

  /// The project's name.
  final String seed;

  /// The accent ring's color — the card's kind, or the theme's primary.
  final Color? accentColor;

  /// Eight quieter rings with no dot, for cards that hold more text.
  final bool quiet;

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
            arcs: cornerRingArcs(seed, quiet: quiet),
            center: const Offset(100, 0),
            viewBox: const Size(100, 100),
            lineWidth: 0.5,
            accentWidth: quiet ? 0.75 : 1,
            dotRadius: 1.8,
            lineColor: theme.brand.line,
            accentColor: accentColor ?? theme.colors.primary,
          ),
        ),
      ),
    );
  }
}
