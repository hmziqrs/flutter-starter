import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/fx/shaders/brand_material_recipe.dart';
import 'package:starter/shared/fx/shaders/brand_material_surface.dart';

/// An outline card crowned with a brand-material band (the kit's
/// `material-card`, cover variant): the thin text-color line at 10% and
/// transparent fill carry the card, the material lives only in the top band
/// at the kit's 16:10 of the card's width, and a hairline parts the band
/// from the words — material never sits behind text (BRAND.md s13).
class MaterialCard extends StatelessWidget {
  const MaterialCard({
    required this.recipe,
    required this.child,
    this.bandExtent,
    this.padding = const EdgeInsets.all(24),
    super.key,
  });

  final BrandMaterialRecipe recipe;

  /// The card's body, laid out under the band.
  final Widget child;

  /// The band's height; null keeps the kit's cover proportion, 16:10 of the
  /// card's width.
  final double? bandExtent;

  /// Padding around [child] (the kit's p-6).
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final radius = theme.style.borderRadius.lg.resolve(Directionality.of(context));
    return Container(
      foregroundDecoration: ShapeDecoration(
        color: Colors.transparent,
        // The kit's `ring-1 ring-foreground/10`: one hairline, no fill.
        shape: RoundedSuperellipseBorder(
          side: BorderSide(color: theme.colors.foreground.withValues(alpha: 0.1)),
          borderRadius: theme.style.borderRadius.lg,
        ),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final band = bandExtent ?? constraints.maxWidth * 10 / 16;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  height: band,
                  child: BrandMaterialSurface(recipe: recipe),
                ),
                // The kit's `border-b` under the cover band.
                Container(height: theme.style.borderWidth, color: theme.colors.border),
                Padding(padding: padding, child: child),
              ],
            );
          },
        ),
      ),
    );
  }
}
