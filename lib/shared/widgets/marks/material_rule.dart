import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/fx/shaders/brand_material_recipe.dart';
import 'package:starter/shared/fx/shaders/brand_material_surface.dart';

/// A thin brand-material strip used as a divider (the shader-kit variant of
/// the rule): the page's sections usually part at a hairline; the material
/// rule marks the one division worth a signature, so it never appears twice
/// on a screen.
class MaterialRule extends StatelessWidget {
  const MaterialRule({required this.recipe, this.height = 4, super.key});

  final BrandMaterialRecipe recipe;

  /// Strip thickness; hairline-thin at 4.
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final radius = theme.style.borderRadius.sm.resolve(Directionality.of(context));
    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: BrandMaterialSurface(
          recipe: recipe,
        ),
      ),
    );
  }
}
