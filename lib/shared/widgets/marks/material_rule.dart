import 'dart:ui' as ui show Gradient;

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/fx/shaders/brand_material_recipe.dart';
import 'package:starter/shared/fx/shaders/brand_material_surface.dart';

/// A thin brand-material strip used as a divider (the kits' `material-rule`):
/// a 3px strip of metal between sections, fading at its ends — the page's
/// sections usually part at a hairline, and the material rule marks the one
/// division worth a signature, so it never appears twice on a screen.
class MaterialRule extends StatelessWidget {
  const MaterialRule({required this.recipe, this.height = 3, this.fade = true, super.key});

  final BrandMaterialRecipe recipe;

  /// Strip thickness; the kit draws 3px.
  final double height;

  /// Fades the strip out at both ends (the kit's
  /// `linear-gradient(90deg, transparent, white 18%, white 82%, transparent)`
  /// mask). An alpha-only mask: the gradient's colors never reach the paint.
  final bool fade;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final radius = theme.style.borderRadius.sm.resolve(Directionality.of(context));
    Widget rule = ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: BrandMaterialSurface(recipe: recipe),
      ),
    );
    if (fade) {
      // The kit's end fade as an alpha mask over the strip.
      rule = ShaderMask(
        shaderCallback: (bounds) => ui.Gradient.linear(
          Offset.zero,
          Offset(bounds.width, 0),
          const <Color>[
            Color(0x00FFFFFF),
            Color(0xFFFFFFFF),
            Color(0xFFFFFFFF),
            Color(0x00FFFFFF),
          ],
          const <double>[0, 0.18, 0.82, 1],
        ),
        blendMode: BlendMode.dstIn,
        child: rule,
      );
    }
    return rule;
  }
}
