import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/fx/shaders/brand_material_recipe.dart';
import 'package:starter/shared/fx/shaders/brand_material_surface.dart';

/// A progress bar filled with a brand material (the shader-kit variant of the
/// usage bar): the outline track carries a [BrandMaterialSurface] clipped to
/// the filled share.
///
/// The recipe is the kit's `material-bar`: a 10px pill of a track with only
/// the thin 1px text-color line at 10% for an edge, and the material fill
/// rounded like the track — the track never takes a grey fill (BRAND.md s13).
/// The value carries the meaning; the material is the finish.
class MaterialBar extends StatelessWidget {
  const MaterialBar({required this.recipe, required this.value, this.height = 10, super.key});

  final BrandMaterialRecipe recipe;

  /// The filled share, 0 to 1; clamped into range.
  final double value;

  /// Track thickness; the kit draws 10px (h-2.5).
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final radius = BorderRadius.circular(height / 2);
    return Container(
      height: height,
      width: double.infinity,
      // The kit's `ring-1 ring-foreground/10`: one hairline, no fill.
      foregroundDecoration: ShapeDecoration(
        color: Colors.transparent,
        shape: RoundedSuperellipseBorder(
          side: BorderSide(color: theme.colors.foreground.withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(height / 2),
        ),
      ),
      child: ClipRRect(
        borderRadius: radius,
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
                // The kit's fill carries `rounded-full`, so its moving end
                // stays a pill instead of a hard vertical cut.
                child: ClipRRect(
                  borderRadius: radius,
                  child: BrandMaterialSurface(recipe: recipe),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
