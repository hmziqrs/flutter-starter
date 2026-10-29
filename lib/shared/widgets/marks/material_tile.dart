import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/fx/shaders/brand_material_recipe.dart';
import 'package:starter/shared/fx/shaders/brand_material_surface.dart';

/// Square with 22%-of-size corners, or a circle.
enum MaterialTileShape { square, circle }

/// A small tile cut from a brand material (the kit's `material-tile`): the
/// material fills the tile — clipped to a square whose corners round by 22%
/// of the edge, or to a circle — with no outline; the line is the shape
/// itself. With a [child] the material becomes its frame: the child sits on
/// a page-colored panel inset by [frameShare] of the size (never under 2px),
/// rounded a little tighter than the tile, the way the kit's framed letters
/// and icons draw (BRAND.md s13: words never sit on raw metal).
///
/// Pass a recipe from `brand_materials.dart`; a grid of tiles keeps one
/// recipe per material and never repeats one inside a view.
class MaterialTile extends StatelessWidget {
  const MaterialTile({
    required this.recipe,
    this.size = 96,
    this.shape = MaterialTileShape.square,
    this.frameShare = 0.1,
    this.child,
    super.key,
  });

  final BrandMaterialRecipe recipe;

  /// The tile's edge length; the material renders as a square of this size.
  final double size;

  /// Square with 22%-of-size corners, or a circle.
  final MaterialTileShape shape;

  /// The frame's thickness as a share of the size (the kit's `frame`).
  final double frameShare;

  /// Content framed by the material — an icon or two letters. Sizing is the
  /// caller's: the kit sets letters to 34% of the size and icons to 45%.
  final Widget? child;

  BorderRadius get _outerRadius => shape == MaterialTileShape.circle
      ? BorderRadius.circular(size / 2)
      : BorderRadius.circular(size * 0.22);

  BorderRadius get _innerRadius => shape == MaterialTileShape.circle
      ? BorderRadius.circular(size / 2)
      : BorderRadius.circular(size * 0.18);

  /// The kit's inset: `max(2, round(size * frame))` px.
  double get _inset => math.max(2, (size * frameShare).roundToDouble());

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final material = ClipRRect(
      borderRadius: _outerRadius,
      child: SizedBox.square(
        dimension: size,
        child: BrandMaterialSurface(recipe: recipe),
      ),
    );
    final content = child;
    if (content == null) {
      return material;
    }
    return SizedBox.square(
      dimension: size,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          material,
          Padding(
            padding: EdgeInsets.all(_inset),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colors.background,
                borderRadius: _innerRadius,
              ),
              child: Center(child: content),
            ),
          ),
        ],
      ),
    );
  }
}
