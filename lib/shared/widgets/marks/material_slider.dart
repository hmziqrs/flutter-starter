import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/fx/shaders/brand_material_recipe.dart';
import 'package:starter/shared/fx/shaders/brand_material_surface.dart';

/// A slider whose filled part carries a brand material (the kit's
/// `material-slider`): the outline track fills with material up to the thumb,
/// and the thumb itself stays a page-colored stud in the primary line — the
/// value carries the meaning; the material is only the fill.
///
/// Drag or tap to set.
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
  // The kit's track: 0.625rem (10px) tall, transparent with a 1px inset
  // text-color line at 12% — never a grey fill.
  static const _trackExtent = 10.0;

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
                    // The track: an outline stadium the material fill sits in
                    // (the kit's inset 1px foreground/12% ring).
                    Container(
                      height: _trackExtent,
                      width: width,
                      foregroundDecoration: ShapeDecoration(
                        color: Colors.transparent,
                        shape: RoundedSuperellipseBorder(
                          side: BorderSide(
                            color: theme.colors.foreground.withValues(alpha: 0.12),
                          ),
                          borderRadius: const BorderRadius.all(
                            Radius.circular(_trackExtent / 2),
                          ),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(_trackExtent / 2),
                        ),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: SizedBox(
                            width: (width - _thumbExtent) * share + _thumbExtent / 2,
                            height: _trackExtent,
                            // The kit's fill carries `rounded-full`, so its
                            // moving end stays a pill.
                            child: ClipRRect(
                              borderRadius: const BorderRadius.all(
                                Radius.circular(_trackExtent / 2),
                              ),
                              child: BrandMaterialSurface(recipe: widget.recipe),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // The thumb: a page-colored circle in the kit's 2px
                    // primary border — no material in it, the fill alone
                    // carries the metal.
                    Positioned(
                      left: (width - _thumbExtent) * share,
                      child: Container(
                        width: _thumbExtent,
                        height: _thumbExtent,
                        decoration: ShapeDecoration(
                          color: theme.colors.background,
                          shape: RoundedSuperellipseBorder(
                            side: BorderSide(color: theme.colors.primary, width: 2),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(_thumbExtent / 2),
                            ),
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
