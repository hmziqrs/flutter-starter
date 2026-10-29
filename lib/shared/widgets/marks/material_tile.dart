import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/fx/shaders/brand_material_recipe.dart';
import 'package:starter/shared/fx/shaders/brand_material_surface.dart';

/// A square outline tile filled with a brand material (the shader-kit
/// material system): the procedural [BrandMaterialSurface] clipped to the
/// tile's rounded square, with the thin theme line drawn on top.
///
/// Like every tile that sits in the page, the line is the tile — there is
/// no grey fill behind the material (BRAND.md s13). Pass a recipe from
/// `brand_materials.dart`; a grid of material tiles keeps one recipe per
/// material and never repeats one inside a view.
class MaterialTile extends StatelessWidget {
  const MaterialTile({required this.recipe, this.size = 96, super.key});

  final BrandMaterialRecipe recipe;

  /// The tile's edge length; the material renders as a square of this size.
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final radius = theme.style.borderRadius.lg.resolve(Directionality.of(context));
    return Container(
      width: size,
      height: size,
      foregroundDecoration: ShapeDecoration(
        color: Colors.transparent,
        shape: RoundedSuperellipseBorder(
          side: BorderSide(color: theme.colors.border, width: theme.style.borderWidth),
          borderRadius: theme.style.borderRadius.lg,
        ),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BrandMaterialSurface(recipe: recipe),
      ),
    );
  }
}
