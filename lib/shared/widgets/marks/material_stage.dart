import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/fx/shaders/brand_material_recipe.dart';
import 'package:starter/shared/fx/shaders/brand_material_surface.dart';

/// A wide brand-material stage (the kits' `material-stage`): the material
/// fills the stage and the [child] rides inside a solid page-colored window
/// with the thin theme line and a shadow — content never sits bare on the
/// metal. The optional [title] names the window's contents, like the kit's
/// title bar (a file or page name).
///
/// Words on glass without a window belong on `MaterialCard`, not here.
/// Window content is display-size and brief — body copy never sits on a
/// stage (BRAND.md s7).
class MaterialStage extends StatelessWidget {
  const MaterialStage({required this.recipe, this.extent = 160, this.title, this.child, super.key});

  final BrandMaterialRecipe recipe;

  /// Stage height; it stretches to the given width.
  final double extent;

  /// A title bar on the window, e.g. the file or page name; null draws none.
  final String? title;

  /// Content riding in the stage's window.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final windowRadius = theme.style.borderRadius.md.resolve(Directionality.of(context));
    return Container(
      foregroundDecoration: ShapeDecoration(
        color: Colors.transparent,
        shape: RoundedSuperellipseBorder(
          side: BorderSide(color: theme.colors.foreground.withValues(alpha: 0.1)),
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
              // The stage's material, edge to edge behind the window.
              BrandMaterialSurface(recipe: recipe),
              Padding(
                padding: const EdgeInsets.all(16),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colors.background,
                    borderRadius: windowRadius,
                    border: Border.fromBorderSide(
                      BorderSide(color: theme.colors.border, width: theme.style.borderWidth),
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: theme.colors.background.withValues(alpha: 0.6),
                        offset: const Offset(0, 20),
                        blurRadius: 25,
                        spreadRadius: -5,
                      ),
                      BoxShadow(
                        color: theme.colors.background.withValues(alpha: 0.6),
                        offset: const Offset(0, 8),
                        blurRadius: 10,
                        spreadRadius: -6,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (title != null)
                        Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: theme.colors.border,
                                width: theme.style.borderWidth,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Text(
                            title!,
                            style: theme.typography.body.xs.copyWith(
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                        ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: child,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
