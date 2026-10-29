import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/fx/shaders/brand_material_recipe.dart';
import 'package:starter/shared/fx/shaders/brand_material_surface.dart';

/// A framed material plinth: the material quad floats inside the thin theme
/// line with a page-colored mat between them, the way a print sits in a
/// frame. Optional content rides on the material.
///
/// The mat is the page showing through — no fill of its own (BRAND.md s13),
/// so the frame reads on any surface.
class MaterialFrame extends StatelessWidget {
  const MaterialFrame({
    required this.recipe,
    this.inset = 8,
    this.extent = 120,
    this.child,
    this.padding,
    super.key,
  });

  final BrandMaterialRecipe recipe;

  /// The mat's thickness between the line and the material.
  final double inset;

  /// The material's height inside the frame.
  final double extent;

  /// Content drawn over the material, inside [padding].
  final Widget? child;

  /// Padding around [child].
  final EdgeInsetsGeometry? padding;

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
      padding: EdgeInsets.all(inset),
      child: ClipRRect(
        borderRadius: theme.style.borderRadius.md.resolve(Directionality.of(context)),
        child: SizedBox(
          height: extent,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              BrandMaterialSurface(recipe: recipe),
              if (child != null)
                Positioned.fill(
                  child: padding == null
                      ? Center(child: child)
                      : Padding(padding: padding!, child: child),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
