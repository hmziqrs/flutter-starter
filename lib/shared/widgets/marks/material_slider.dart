import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/fx/shaders/brand_material_recipe.dart';
import 'package:starter/shared/fx/shaders/brand_material_surface.dart';

/// A slider whose fill and thumb carry a brand material (the shader-kit
/// variant of the slider): the muted track fills with material up to the
/// thumb, and the thumb itself is a material stud in the thin theme line.
///
/// Drag or tap to set. The value carries the meaning; the material is the
/// finish.
class MaterialSlider extends StatefulWidget {
  const MaterialSlider({
    required this.recipe,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
    super.key,
  });

  final BrandMaterialRecipe recipe;

  /// The current position, 0 to 1; clamped into range.
  final double value;

  /// Called with the new position while the user drags or taps.
  final ValueChanged<double> onChanged;

  /// What screen readers call the control, e.g. "Material slider".
  final String? semanticLabel;

  @override
  State<MaterialSlider> createState() => _MaterialSliderState();
}

class _MaterialSliderState extends State<MaterialSlider> {
  static const _trackExtent = 8.0;

  static const _thumbExtent = 20.0;

  void _setFromLocalX(double x, double width) {
    widget.onChanged((x / width).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final share = widget.value.clamp(0.0, 1.0);
    return Semantics(
      container: widget.semanticLabel != null,
      label: widget.semanticLabel,
      slider: true,
      value: '${(share * 100).round()}%',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) => _setFromLocalX(details.localPosition.dx, width),
            onHorizontalDragUpdate: (details) => _setFromLocalX(details.localPosition.dx, width),
            child: SizedBox(
              height: _thumbExtent,
              child: Center(
                child: Stack(
                  alignment: AlignmentDirectional.centerStart,
                  children: <Widget>[
                    // The track: a muted stadium the material fill sits in.
                    ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(_trackExtent / 2)),
                      child: Container(
                        height: _trackExtent,
                        width: width,
                        color: theme.colors.muted,
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: SizedBox(
                            width: (width - _thumbExtent) * share + _thumbExtent / 2,
                            height: _trackExtent,
                            child: BrandMaterialSurface(recipe: widget.recipe),
                          ),
                        ),
                      ),
                    ),
                    // The thumb: a material stud in a page-colored ring and
                    // the theme line.
                    Positioned(
                      left: (width - _thumbExtent) * share,
                      child: Container(
                        width: _thumbExtent,
                        height: _thumbExtent,
                        decoration: ShapeDecoration(
                          color: theme.colors.background,
                          shape: RoundedSuperellipseBorder(
                            side: BorderSide(
                              color: theme.colors.border,
                              width: theme.style.borderWidth,
                            ),
                            borderRadius: const BorderRadius.all(Radius.circular(_thumbExtent / 2)),
                          ),
                        ),
                        padding: const EdgeInsets.all(5),
                        child: ClipOval(
                          child: SizedBox.expand(
                            child: BrandMaterialSurface(recipe: widget.recipe),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
