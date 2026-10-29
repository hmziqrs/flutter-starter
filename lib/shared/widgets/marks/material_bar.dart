import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/fx/shaders/brand_material_recipe.dart';
import 'package:starter/shared/fx/shaders/brand_material_surface.dart';

/// A progress bar filled with a brand material (the shader-kit variant of the
/// usage bar): the muted track carries a [BrandMaterialSurface] clipped to
/// the filled share.
///
/// Like every material placement, the material fills the bar — it never
/// washes the row around it (BRAND.md s13). The value carries the meaning;
/// the material is the finish.
class MaterialBar extends StatelessWidget {
  const MaterialBar({required this.recipe, required this.value, this.height = 8, super.key});

  final BrandMaterialRecipe recipe;

  /// The filled share, 0 to 1; clamped into range.
  final double value;

  /// Track thickness.
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final radius = theme.style.borderRadius.lg.resolve(Directionality.of(context));
    return ClipRRect(
      borderRadius: radius,
      child: Container(
        height: height,
        width: double.infinity,
        color: theme.colors.muted,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final share = value.clamp(0.0, 1.0);
            if (share <= 0) {
              return const SizedBox.expand();
            }
            final extent = constraints.maxWidth * share;
            return Align(
              alignment: AlignmentDirectional.centerStart,
              child: SizedBox(
                width: extent,
                height: double.infinity,
                child: BrandMaterialSurface(recipe: recipe),
              ),
            );
          },
        ),
      ),
    );
  }
}
