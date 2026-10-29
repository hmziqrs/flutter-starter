import 'dart:async' show unawaited;

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/fx/oklab.dart';
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

/// A material finished as a sheet (the kit's `data-material-sheet` in
/// materials.css): a floor of the text color mixed 24% into the page color
/// under the metal, multiplied onto it in light mode and screened in dark
/// mode, so the material's dark and light patches stay readable on either
/// page color.
///
/// Masked pieces (the gauge, the rings, the sparkline area) draw this instead
/// of the bare [BrandMaterialSurface]; plain placements (tiles, bars, rules)
/// keep the bare quad, like the kit's plain `bg-cover` uses.
class BrandMaterialSheet extends StatefulWidget {
  const BrandMaterialSheet({required this.recipe, this.time, super.key});

  final BrandMaterialRecipe recipe;

  /// Renders one exact frame and skips the animation clock when set
  /// (posters, goldens, thumbnails).
  final double? time;

  @override
  State<BrandMaterialSheet> createState() => _BrandMaterialSheetState();
}

class _BrandMaterialSheetState extends State<BrandMaterialSheet>
    with SingleTickerProviderStateMixin {
  static const _cycleSeconds = 60;

  late final AnimationController _clock = AnimationController(vsync: this);

  Future<BrandMaterialProgram>? _program;

  bool get _wantsMotion => widget.time == null && !MediaQuery.disableAnimationsOf(context);

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
  void didUpdateWidget(BrandMaterialSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncClock();
  }

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
    final colors = context.theme.colors;
    final floor = oklabMix(colors.background, colors.foreground, 0.24);
    // Light mode multiplies the metal into the floor; dark mode screens it.
    final blend = colors.brightness == Brightness.dark ? BlendMode.screen : BlendMode.multiply;
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
          painter: _SheetPainter(
            program: loaded,
            recipe: widget.recipe,
            time: time,
            floor: floor,
            blend: blend,
            repaint: _wantsMotion ? _clock : null,
          ),
        );
      },
    );
  }
}

class _SheetPainter extends CustomPainter {
  _SheetPainter({
    required this.program,
    required this.recipe,
    required this.time,
    required this.floor,
    required this.blend,
    super.repaint,
  });

  final BrandMaterialProgram program;
  final BrandMaterialRecipe recipe;
  final double time;
  final Color floor;

  /// Multiply in light mode, screen in dark (materials.css).
  final BlendMode blend;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }
    // The kit's `isolation: isolate`: the sheet blends within its own layer,
    // so multiply/screen never reaches whatever sits behind the sheet.
    final bounds = Offset.zero & size;
    final shader = program.newShader();
    try {
      applyBrandMaterialUniforms(
        shader,
        brandMaterialUniforms(recipe: recipe, width: size.width, height: size.height, time: time),
      );
      program.bindBlankSampler(shader);
      canvas
        ..saveLayer(bounds, Paint())
        // The floor keeps the metal's dark and light patches readable, the
        // way the kit's `data-part="floor"` rect does under the metal image.
        ..drawRect(bounds, Paint()..color = floor)
        ..drawRect(
          bounds,
          Paint()
            ..shader = shader
            ..blendMode = blend,
        );
    } finally {
      shader.dispose();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SheetPainter oldDelegate) =>
      !identical(program, oldDelegate.program) ||
      recipe != oldDelegate.recipe ||
      time != oldDelegate.time ||
      floor != oldDelegate.floor ||
      blend != oldDelegate.blend;
}
