import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/fx/shaders/brand_material_recipe.dart';
import 'package:starter/shared/fx/shaders/brand_material_surface.dart';

/// A tag whose leading mark is a brand-material quad (the shader-kit variant
/// of the status tag): the pill keeps the thin theme line, and the material
/// lives in the little square only — tags stay outline pieces, never
/// material-filled chips (BRAND.md s13).
class MaterialTag extends StatelessWidget {
  const MaterialTag({
    required this.recipe,
    required this.label,
    this.markSize = 12,
    super.key,
  });

  final BrandMaterialRecipe recipe;

  /// The tag's label. Sentence case comes from the caller.
  final String label;

  /// Edge length of the material mark.
  final double markSize;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final radius = theme.style.borderRadius.sm.resolve(Directionality.of(context));
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: ShapeDecoration(
        color: Colors.transparent,
        shape: RoundedSuperellipseBorder(
          side: BorderSide(color: theme.colors.border, width: theme.style.borderWidth),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ClipRRect(
            borderRadius: radius,
            child: SizedBox.square(
              dimension: markSize,
              child: BrandMaterialSurface(recipe: recipe),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.typography.body.xs.copyWith(
              color: theme.colors.foreground,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
