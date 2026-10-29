import 'dart:async' show unawaited;

import 'package:flutter/widgets.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/fx/shaders/brand_material_program.dart';
import 'package:starter/shared/fx/shaders/brand_material_recipe.dart';
import 'package:starter/shared/fx/shaders/brand_materials.dart';

/// Text filled with a brand material instead of flat color: the text raster
/// becomes the alpha mask over a live material frame, matching the brand
/// kit's `material-text.ts`.
///
/// The recipe is one of the sixteen approved [brandMaterials] (or an explicit
/// [recipe]); [zoom], [offsetX] and [offsetY] pan across the material the way
/// the web kit's look settings do, and [seed] pins both layers' lattice
/// offsets. Motion follows the ambient-art contract: it stops under reduced
/// motion or [paused], rendering the still frame at [time].
class BrandMaterialText extends StatefulWidget {
  const BrandMaterialText({
    required this.text,
    this.materialId = 'copper-sweep',
    this.recipe,
    this.fontFamily = 'Onest',
    this.fontWeight = FontWeight.w800,
    this.fontSize = 48,
    this.letterSpacing = -0.05,
    this.lineHeight = 0.96,
    this.textAlign = TextAlign.left,
    this.zoom = 1,
    this.offsetX = 50,
    this.offsetY = 50,
    this.amount = 1,
    this.tintAmount = 0,
    this.speed = 1,
    this.time = 0,
    this.seed = -1,
    this.animated = true,
    this.paused = false,
    this.maxLines,
    super.key,
  });

  /// The string to fill. Line breaks are honored by [Text].
  final String text;

  /// Which approved material to use when [recipe] is null.
  final String materialId;

  /// An explicit recipe overriding [materialId] entirely.
  final BrandMaterialRecipe? recipe;

  final String fontFamily;
  final FontWeight fontWeight;
  final double fontSize;

  /// Tracking in em (the kit's wordmark default tightens to -0.05).
  final double letterSpacing;

  /// Line height multiplier.
  final double lineHeight;
  final TextAlign textAlign;

  /// Material framing: [zoom] scales the field, [offsetX]/[offsetY] place
  /// the window in percent (50/50 is the center).
  final double zoom;
  final double offsetX;
  final double offsetY;

  /// 1 = full material, 0 = the flat tint color.
  final double amount;

  /// How far the material tints toward the theme foreground, 0 to 1.
  final double tintAmount;

  /// Time base and animation speed for the material drift.
  final double speed;
  final double time;

  /// Pins the lattice seeds of both layers when >= 0; -1 keeps the recipe's.
  final int seed;

  /// Whether the material drifts at all.
  final bool animated;

  /// Freezes at the current frame while true (a pause hook).
  final bool paused;

  final int? maxLines;

  @override
  State<BrandMaterialText> createState() => _BrandMaterialTextState();
}

class _BrandMaterialTextState extends State<BrandMaterialText> with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(vsync: this);
  Future<BrandMaterialProgram>? _program;

  bool get _wantsMotion =>
      widget.animated && !widget.paused && !MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    _program = BrandMaterialProgram.load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncClock();
  }

  @override
  void didUpdateWidget(BrandMaterialText oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncClock();
  }

  /// Same advance-and-wrap-at-60 clock as the surface: one repeat is a full
  /// shader-time cycle at the look's speed.
  void _syncClock() {
    if (!_wantsMotion) {
      if (_clock.isAnimating) {
        _clock.stop();
      }
      return;
    }
    final period = Duration(milliseconds: (60 / widget.speed.clamp(0.25, 2) * 1000).round());
    if (_clock.duration != period) {
      _clock.duration = period;
      unawaited(_clock.repeat());
    } else if (!_clock.isAnimating) {
      unawaited(_clock.repeat());
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  /// The recipe as the web kit's `materialTextRecipe` derives it: the preset
  /// re-framed by the look's zoom and centered offsets, with the look's speed,
  /// time and (when pinned) layer seeds — then clamped back into schema range.
  BrandMaterialRecipe _recipe() {
    final base = widget.recipe ?? brandMaterialById(widget.materialId) ?? brandMaterials.first;
    final seed = widget.seed;
    return base
        .copyWith(
          zoom: base.zoom * widget.zoom,
          offsetX: (widget.offsetX - 50) * 2,
          offsetY: (widget.offsetY - 50) * 2,
          speed: widget.speed,
          time: widget.time,
          a: seed >= 0 ? base.a.copyWith(seed: seed.toDouble()) : null,
          b: seed >= 0 ? base.b.copyWith(seed: (seed + 1).toDouble()) : null,
        )
        .clamped();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final recipe = _recipe();
    final time = _wantsMotion ? (recipe.time + _clock.value * 60) % 60 : recipe.time;
    return FutureBuilder<BrandMaterialProgram>(
      future: _program,
      builder: (context, snapshot) {
        final program = snapshot.data;
        if (program == null) {
          return const SizedBox.shrink();
        }
        return AnimatedSampler(
          (
            image,
            size,
            canvas,
          ) {
            final shader = program.newShader();
            try {
              applyBrandMaterialUniforms(
                shader,
                brandMaterialUniforms(
                  recipe: recipe,
                  width: size.width,
                  height: size.height,
                  time: time,
                  mask: true,
                  amount: widget.amount.clamp(0, 1),
                  tintAmount: widget.tintAmount.clamp(0, 1),
                  tint: colors.foreground,
                ),
              );
              shader.setImageSampler(0, image);
              canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
            } finally {
              shader.dispose();
            }
          },
          child: Text(
            widget.text,
            textAlign: widget.textAlign,
            maxLines: widget.maxLines,
            style: TextStyle(
              fontFamily: widget.fontFamily,
              fontSize: widget.fontSize,
              fontWeight: widget.fontWeight,
              height: widget.lineHeight,
              letterSpacing: widget.letterSpacing * widget.fontSize,
              // The shader reads only this raster's alpha; the color is
              // irrelevant, so the theme foreground keeps it token-sourced.
              color: colors.foreground,
            ),
          ),
        );
      },
    );
  }
}
