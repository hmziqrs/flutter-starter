import 'package:flutter/material.dart';
import 'package:starter/shared/fx/shaders/brand_material_recipe.dart';
import 'package:starter/shared/fx/shaders/brand_material_surface.dart';

/// Decorative rings cut out of a brand-material quad (the shader-kit variant
/// of the corner rings): the material shows through the ring strokes and the
/// page shows through the gaps, so a material can carry the ring motif
/// without a single stroked circle.
class MaterialRings extends StatelessWidget {
  const MaterialRings({required this.recipe, this.size = 96, this.count = 4, super.key});

  final BrandMaterialRecipe recipe;

  /// Edge length of the square the rings paint in.
  final double size;

  /// Ring count, at least 1.
  final int count;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: ClipPath(
        clipper: _RingApertureClipper(count: count.clamp(1, 12)),
        child: BrandMaterialSurface(recipe: recipe),
      ),
    );
  }
}

/// Cuts `count` concentric ring bands out of the quad; everything outside
/// the bands (gaps, center disc, outside the outer ring) shows the page.
class _RingApertureClipper extends CustomClipper<Path> {
  const _RingApertureClipper({required this.count});

  final int count;

  @override
  Path getClip(Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = size.shortestSide / 2;
    // Ring thickness and gap share the radius so any count fits the square.
    final band = maxRadius / (count * 2 - 1);
    final path = Path()..fillType = PathFillType.evenOdd;
    for (var index = 0; index < count; index++) {
      final outer = maxRadius - index * 2 * band;
      final inner = outer - band;
      if (inner <= 0) {
        break;
      }
      path
        ..addOval(Rect.fromCircle(center: center, radius: outer))
        ..addOval(Rect.fromCircle(center: center, radius: inner));
    }
    return path;
  }

  @override
  bool shouldReclip(_RingApertureClipper oldClipper) => oldClipper.count != count;
}
