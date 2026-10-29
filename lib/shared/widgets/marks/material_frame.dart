import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/fx/shaders/brand_material_recipe.dart';
import 'package:starter/shared/fx/shaders/brand_material_surface.dart';

/// A thin frame cut from a brand material (the kits' `material-frame`): the
/// material runs as a band of [inset] px around an inner page-colored panel,
/// and the content sits on the page color — the one plan, project or sample
/// that leads a row. The band's inner corners tighten by the band width, the
/// way the kit's `calc(var(--radius) + 4px - width)` does.
class MaterialFrame extends StatelessWidget {
  const MaterialFrame({
    required this.recipe,
    this.inset = 6,
    this.extent = 120,
    this.child,
    this.padding,
    super.key,
  });

  final BrandMaterialRecipe recipe;

  /// The material band's thickness in px (the kit's `width`).
  final double inset;

  /// The frame's height; content taller than it stretches the frame.
  final double extent;

  /// Content on the inner page-colored panel.
  final Widget? child;

  /// Padding around [child] inside the panel.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final outerRadius = theme.style.borderRadius.lg.resolve(Directionality.of(context));
    final innerRadius = BorderRadius.circular(
      math.max(0, outerRadius.bottomLeft.x - inset),
    );
    return ClipRRect(
      borderRadius: outerRadius,
      child: SizedBox(
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            // The material quad; the inner panel covers all but the band.
            Positioned.fill(child: BrandMaterialSurface(recipe: recipe)),
            Padding(
              padding: EdgeInsets.all(inset),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colors.background,
                  borderRadius: innerRadius,
                ),
                child: SizedBox(
                  height: extent,
                  width: double.infinity,
                  child: child == null
                      ? null
                      : Padding(
                          padding: padding ?? const EdgeInsets.all(24),
                          child: child,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
