import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/fx/shaders/brand_material_recipe.dart';
import 'package:starter/shared/fx/shaders/brand_material_surface.dart';

/// A small label whose pill border is a brand material (the kit's
/// `material-tag`): a 23px pill where the metal runs as a 1.5px cover around
/// an inner page-colored pill, so the one word that should catch the eye —
/// "Pro", "Recommended", "New" — keeps its text on the page color and the
/// material only draws the edge (BRAND.md s13).
class MaterialTag extends StatelessWidget {
  const MaterialTag({required this.recipe, required this.label, super.key});

  final BrandMaterialRecipe recipe;

  /// The tag's label. Sentence case comes from the caller.
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    // The kit's pill: a 1.5px material cover, the label's 16px line with 2px
    // of air either side — 23px all told, radius at the pill's half.
    const radius = BorderRadius.all(Radius.circular(11.5));
    return SizedBox(
      height: 23,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // The material pill; the inner page-colored pill covers all but
          // the 1.5px edge, exactly the kit's p-[1.5px] material cover.
          ClipRRect(
            borderRadius: radius,
            child: BrandMaterialSurface(recipe: recipe),
          ),
          Padding(
            padding: const EdgeInsets.all(1.5),
            child: DecoratedBox(
              decoration: BoxDecoration(color: theme.colors.background, borderRadius: radius),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Center(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.typography.body.xs.copyWith(
                      color: theme.colors.foreground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
