import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/fx/shaders/brand_material_recipe.dart';
import 'package:starter/shared/fx/shaders/brand_material_surface.dart';

/// A wide brand-material stage (the shader-kit variant of the band surface):
/// the material fills the stage and page content rides on top, the closing
/// panel a landing flow ends on.
///
/// Content over a material is display-size and brief — body copy never sits
/// on a material (BRAND.md s7).
class MaterialStage extends StatelessWidget {
  const MaterialStage({required this.recipe, this.extent = 160, this.child, super.key});

  final BrandMaterialRecipe recipe;

  /// Stage height; it stretches to the given width.
  final double extent;

  /// Content riding on the material.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      foregroundDecoration: ShapeDecoration(
        color: Colors.transparent,
        shape: RoundedSuperellipseBorder(
          side: BorderSide(color: theme.colors.border, width: theme.style.borderWidth),
          borderRadius: theme.style.borderRadius.lg,
        ),
      ),
      child: ClipRRect(
        borderRadius: theme.style.borderRadius.lg.resolve(Directionality.of(context)),
        child: SizedBox(
          height: extent,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              BrandMaterialSurface(recipe: recipe),
              if (child != null) Positioned.fill(child: Center(child: child)),
            ],
          ),
        ),
      ),
    );
  }
}
