import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/fx/shaders/brand_material_recipe.dart';
import 'package:starter/shared/fx/shaders/brand_material_surface.dart';

/// An outline card crowned with a brand-material band (the shader-kit card):
/// the thin theme line and transparent fill carry the card, and the material
/// lives only in the top band (BRAND.md s13 — material never sits behind
/// text).
class MaterialCard extends StatelessWidget {
  const MaterialCard({
    required this.recipe,
    required this.child,
    this.bandExtent = 72,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  final BrandMaterialRecipe recipe;

  /// The card's body, laid out under the band.
  final Widget child;

  /// The band's height; the material renders only inside it.
  final double bandExtent;

  /// Padding around [child].
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final radius = theme.style.borderRadius.lg.resolve(Directionality.of(context));
    return Container(
      foregroundDecoration: ShapeDecoration(
        color: Colors.transparent,
        shape: RoundedSuperellipseBorder(
          side: BorderSide(color: theme.colors.border, width: theme.style.borderWidth),
          borderRadius: theme.style.borderRadius.lg,
        ),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              height: bandExtent,
              child: BrandMaterialSurface(recipe: recipe),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}
