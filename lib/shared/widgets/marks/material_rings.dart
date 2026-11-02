import 'dart:async' show unawaited;
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/fx/oklab.dart';
import 'package:starter/shared/fx/shaders/brand_material_program.dart';
import 'package:starter/shared/fx/shaders/brand_material_recipe.dart';
import 'package:starter/shared/widgets/rings/brand_seed.dart';

/// The hero rings cut from a brand material (the kits' `material-rings`):
/// the same seeded arcs as the hero rings for the same name — eleven rings
/// around (440, 225), radius `34 + 34 * i`, seed `hash(seed) + 7`, the accent
/// ring `3 + floor(r() * 3)` — with the faint rings drawn thick enough to
/// carry the material (width `5 + 1.5 * i`) and the accent ring plus its dot
/// painted on top in primary.
///
/// The material shows through the ring strokes and the page shows through the
/// gaps, so a material can carry the ring motif with its one orange accent.
/// The material drifts by the recipe's own speed and stops under reduced
/// motion (BRAND.md s10). Decorative: excluded from semantics.
class MaterialRings extends StatefulWidget {
  const MaterialRings({required this.recipe, this.seed = '', super.key});

  final BrandMaterialRecipe recipe;

  /// The name the ring picture is drawn from; the same name always draws the
  /// same arcs.
  final String seed;

  @override
  State<MaterialRings> createState() => _MaterialRingsState();
}

class _MaterialRingsState extends State<MaterialRings> with SingleTickerProviderStateMixin {
  /// One repeat equals 60 seconds of shader time scaled by the recipe's
  /// speed — the same advance-and-wrap-at-60 rule the web renderer uses.
  static const _cycleSeconds = 60;

  late final AnimationController _clock = AnimationController(vsync: this);

  Future<BrandMaterialProgram>? _program;

  List<RingArc> _arcs = const <RingArc>[];

  @override
  void initState() {
    super.initState();
    _program = BrandMaterialProgram.load();
    _draw();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncClock();
  }

  @override
  void didUpdateWidget(MaterialRings oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seed != widget.seed) {
      _draw();
    }
    _syncClock();
  }

  void _draw() {
    final random = SeededRandom(hashName(widget.seed) + 7);
    final accent = 3 + random.nextIndex(3);
    _arcs = seedArcs(
      random,
      cx: 440,
      cy: 225,
      radii: <double>[for (var i = 0; i < 11; i += 1) 34.0 + 34 * i],
      accent: accent,
      accentGap: 0.52,
      gapRange: (0.06, 0.3),
    );
  }

  void _syncClock() {
    if (MediaQuery.disableAnimationsOf(context)) {
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
    return ExcludeSemantics(
      child: AspectRatio(
        aspectRatio: 520 / 440,
        child: FutureBuilder<BrandMaterialProgram>(
          future: _program,
          builder: (context, snapshot) {
            final program = snapshot.data;
            if (program == null) {
              return const SizedBox.expand();
            }
            return AnimatedBuilder(
              animation: _clock,
              builder: (context, _) {
                final theme = context.theme;
                return CustomPaint(
                  painter: _MaterialRingsPainter(
                    program: program,
                    recipe: widget.recipe,
                    arcs: _arcs,
                    accentColor: theme.colors.primary,
                    floor: oklabMix(theme.colors.background, theme.colors.foreground, 0.24),
                    blend: theme.colors.brightness == Brightness.dark
                        ? BlendMode.screen
                        : BlendMode.multiply,
                    time: _clock.value * _cycleSeconds,
                    repaint: _clock.isAnimating ? _clock : null,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Paints the masked material rings: the sheet's floor and metal kept only
/// where the thick faint ring strokes sit (a `dstIn` layer, the web kit's
/// SVG mask over its data-material-sheet group), then the accent ring and
/// its dot on top.
class _MaterialRingsPainter extends CustomPainter {
  _MaterialRingsPainter({
    required this.program,
    required this.recipe,
    required this.arcs,
    required this.accentColor,
    required this.floor,
    required this.blend,
    required this.time,
    super.repaint,
  });

  final BrandMaterialProgram program;
  final BrandMaterialRecipe recipe;
  final List<RingArc> arcs;
  final Color accentColor;

  /// The sheet floor (the kit's `data-part="floor"`), under the metal.
  final Color floor;

  /// Multiply in light mode, screen in dark (materials.css).
  final BlendMode blend;

  final double time;

  static const Size _viewBox = Size(520, 440);
  static const Offset _center = Offset(440, 225);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }
    final scale = size.width / _viewBox.width;
    canvas
      ..save()
      ..clipRect(Offset.zero & size)
      ..scale(scale);

    // Sheet and mask in one isolated layer: floor under the metal, the metal
    // multiplied/screened onto it (materials.css), then dstIn keeps only the
    // strokes' alpha — the gaps go fully transparent and the page shows
    // through, like the kit's mask. The canvas is scaled into viewBox units
    // by now, so the layer bounds must be too: a device-px rect would cover
    // only `scale` of the surface and clip the rings into its top-left
    // corner.
    final bounds = Offset.zero & _viewBox;
    final shader = program.newShader();
    try {
      applyBrandMaterialUniforms(
        shader,
        brandMaterialUniforms(
          recipe: recipe,
          width: size.width,
          height: size.height,
          time: time,
        ),
      );
      program.bindBlankSampler(shader);
      canvas
        ..saveLayer(bounds, Paint())
        // The sheet floor, under the metal.
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
    // The mask is its own layer composited with dstIn: a dstIn paint on the
    // arc calls alone would only touch the pixels the strokes cover and
    // leave the sheet intact everywhere else, while a whole layer's restore
    // blends its full bounds — erasing the sheet wherever no stroke drew.
    canvas.saveLayer(bounds, Paint()..blendMode = BlendMode.dstIn);
    final maskPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final (index, arc) in arcs.indexed) {
      if (arc.accent) {
        continue;
      }
      canvas.drawArc(
        Rect.fromCircle(center: _center, radius: arc.radius),
        arc.rotateDegrees * math.pi / 180,
        arc.drawn / arc.radius,
        false,
        maskPaint..strokeWidth = 5.0 + index * 1.5,
      );
    }
    canvas
      ..restore()
      // Composite the masked sheet onto the picture.
      ..restore();

    // The accent ring and its dot, painted on top in primary (never masked).
    for (final arc in arcs) {
      if (!arc.accent) {
        continue;
      }
      canvas.drawArc(
        Rect.fromCircle(center: _center, radius: arc.radius),
        arc.rotateDegrees * math.pi / 180,
        arc.drawn / arc.radius,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = accentColor,
      );
      final end = arc.end;
      if (end != null) {
        canvas.drawCircle(end, 7, Paint()..color = accentColor);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_MaterialRingsPainter oldDelegate) =>
      !identical(program, oldDelegate.program) ||
      recipe != oldDelegate.recipe ||
      arcs != oldDelegate.arcs ||
      accentColor != oldDelegate.accentColor ||
      floor != oldDelegate.floor ||
      blend != oldDelegate.blend ||
      time != oldDelegate.time;
}
