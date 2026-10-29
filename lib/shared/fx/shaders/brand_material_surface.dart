import 'dart:async' show unawaited;

import 'package:flutter/widgets.dart';
import 'package:starter/shared/fx/shaders/brand_material_program.dart';
import 'package:starter/shared/fx/shaders/brand_material_recipe.dart';

/// A procedural brand material quad: the fragment shader runs across the
/// widget's bounds and paints the recipe's material, animated by the recipe's
/// own speed unless told to hold still.
///
/// Motion contract (BRAND.md s10): material drift is ambient brand art, so it
/// stops under reduced motion and renders the still frame at the recipe's
/// `time` field; [paused] freezes it at the current frame without dropping
/// the shader. The widget never reacts to hover, press or focus.
class BrandMaterialSurface extends StatefulWidget {
  const BrandMaterialSurface({
    required this.recipe,
    this.paused = false,
    this.time,
    super.key,
  });

  /// The material recipe to render.
  final BrandMaterialRecipe recipe;

  /// Holds the material at its current frame while true (a pause hook for
  /// sheets, dialogs and hidden tabs).
  final bool paused;

  /// Renders one exact frame and skips the animation clock when set
  /// (posters, goldens, thumbnails).
  final double? time;

  @override
  State<BrandMaterialSurface> createState() => _BrandMaterialSurfaceState();
}

class _BrandMaterialSurfaceState extends State<BrandMaterialSurface>
    with SingleTickerProviderStateMixin {
  static const _cycleSeconds = 60;

  late final AnimationController _clock = AnimationController(vsync: this);
  Future<BrandMaterialProgram>? _program;

  bool get _wantsMotion =>
      widget.time == null && !widget.paused && !MediaQuery.disableAnimationsOf(context);

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
  void didUpdateWidget(BrandMaterialSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncClock();
  }

  /// One repeat equals 60 seconds of shader time scaled by the recipe's own
  /// speed — the same advance-and-wrap-at-60 rule the web renderer uses.
  void _syncClock() {
    if (!_wantsMotion) {
      if (_clock.isAnimating) {
        _clock.stop();
      }
      return;
    }
    final period = Duration(
      milliseconds: (60 / widget.recipe.speed.clamp(0.25, 2) * 1000).round(),
    );
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

  @override
  Widget build(BuildContext context) {
    final program = _program;
    if (program == null) {
      return const SizedBox.expand();
    }
    return FutureBuilder<BrandMaterialProgram>(
      future: program,
      builder: (context, snapshot) {
        final loaded = snapshot.data;
        if (loaded == null) {
          return const SizedBox.expand();
        }
        final time =
            widget.time ?? (_wantsMotion ? _clock.value * _cycleSeconds : widget.recipe.time);
        return CustomPaint(
          painter: _MaterialPainter(
            program: loaded,
            recipe: widget.recipe,
            time: time,
            repaint: _wantsMotion ? _clock : null,
          ),
        );
      },
    );
  }
}

class _MaterialPainter extends CustomPainter {
  _MaterialPainter({
    required this.program,
    required this.recipe,
    required this.time,
    super.repaint,
  });

  final BrandMaterialProgram program;
  final BrandMaterialRecipe recipe;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }
    final shader = program.newShader();
    try {
      applyBrandMaterialUniforms(
        shader,
        brandMaterialUniforms(recipe: recipe, width: size.width, height: size.height, time: time),
      );
      program.bindBlankSampler(shader);
      canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
    } finally {
      shader.dispose();
    }
  }

  @override
  bool shouldRepaint(_MaterialPainter oldDelegate) =>
      !identical(program, oldDelegate.program) ||
      recipe != oldDelegate.recipe ||
      time != oldDelegate.time;
}
