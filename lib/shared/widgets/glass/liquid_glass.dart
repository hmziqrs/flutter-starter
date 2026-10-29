import 'dart:typed_data';
import 'dart:ui' as ui show FragmentShader, ImageFilter;

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/fx/shaders/liquid_glass_program.dart';
import 'package:starter/shared/widgets/glass/glass_style.dart';

// Liquid glass: the web kit's SVG displacement-map refraction, ported as an
// ImageFilter.shader backdrop filter (assets/shaders/liquid_glass.frag). The
// shader bends the backdrop along the pane's rounded-rect normal, strongest
// at the rim, and adds the thin rim highlight. The web kit composes the
// displacement with `blur(2px) saturate(1.6) brightness(1.05)`; the same
// chain rides here as one composed filter — blur and tone folded around the
// shader, never two stacked widgets.
//
// Degradation follows the web kit exactly: where the displacement filter
// cannot run (no Impeller), the pane keeps rendering as frosted glass — the
// frost recipe, blur and all (liquid-glass.svelte's
// `data-glass={liquid ? "clear" : "frost"}`). Only the explicit `fallback`
// flag — the reduced-transparency analog — takes the solid card.
//
// Engine discipline: ImageFilter.shader exists only under Impeller, and
// flutter test runs on Skia, so the widget checks
// ImageFilter.isShaderFilterSupported and takes the frost path while the
// program loads or where the filter is unsupported.
//
// Glass rules carry over unchanged: ONE composed filter per surface, never
// nested (GlassScope asserts), never animated (BRAND.md s10).

/// A liquid glass panel (BRAND.md signature surfaces): content over a
/// refracted backdrop in a rounded pane.
///
/// The lens defaults mirror the web kit's `bend: 40` (a feDisplacementMap
/// scale of 40 is ±20px at the rim) and `edge: 18`; tune [refraction] and
/// [edgeWidth] per surface, never per platform. The shader models one corner
/// radius (the pane's top-start value), so pass a uniform [radius].
class LiquidGlass extends StatefulWidget {
  const LiquidGlass({
    required this.child,
    this.padding,
    this.radius,
    this.refraction = 20,
    this.dispersion = 0,
    this.edgeWidth = 18,
    this.fallback = false,
    super.key,
  });

  /// The panel's content, laid out inside [padding].
  final Widget child;

  /// Padding around [child].
  final EdgeInsetsGeometry? padding;

  /// Corner radius override; the theme's large radius by default.
  final BorderRadius? radius;

  /// Rim displacement at the very edge, in px; the kit's `bend: 40` reads as
  /// ±20px here.
  final double refraction;

  /// Per-channel spread of the rim refraction, in px (a chromatic fringe).
  /// The web kit's feDisplacementMap carries no per-channel split, so the
  /// brand default is 0; a nonzero value is a deliberate embellishment.
  final double dispersion;

  /// How far inland the bend reaches, in px; the kit's `edge: 18`.
  final double edgeWidth;

  /// The honest degraded path for reduced transparency: solid card fill,
  /// same border and shine, no refraction or blur at all. Where the engine
  /// merely lacks the shader filter, the pane frosts instead (see the class
  /// docs).
  final bool fallback;

  @override
  State<LiquidGlass> createState() => _LiquidGlassState();
}

class _LiquidGlassState extends State<LiquidGlass> {
  /// The web kit blurs the refracted backdrop with `blur(2px)` — sigma 1
  /// under the CSS-blur-radius-over-two rule every other glass value uses.
  static const _chainBlurSigma = 1.0;

  /// The web kit's tone over the refraction: `saturate(1.6) brightness(1.05)`,
  /// folded into one color matrix (brightness is a diagonal RGB scale applied
  /// after the saturation, so it multiplies the matrix's three color rows).
  static final Float64List _chainToneMatrix = () {
    final matrix = GlassSurfaceStyle.saturationMatrix(1.6);
    for (var i = 0; i < matrix.length; i++) {
      if (i % 4 != 3) {
        matrix[i] *= 1.05;
      }
    }
    return matrix;
  }();

  static const _rimHighlight = 0.35;

  Future<LiquidGlassProgram>? _program;

  ui.FragmentShader? _shader;

  late BorderRadius _radius;

  @override
  void initState() {
    super.initState();
    _program = LiquidGlassProgram.load();
  }

  @override
  void dispose() {
    _shader?.dispose();
    _shader = null;
    super.dispose();
  }

  BorderRadius _resolveRadius(BuildContext context) =>
      widget.radius ?? context.theme.style.borderRadius.lg;

  /// The one composed backdrop filter of the refracting pane: the shader's
  /// displacement first, then the chain blur, then the tone matrix (compose
  /// applies the inner filter first, matching the CSS chain's left-to-right
  /// `url(#f) blur(2px) saturate(1.6) brightness(1.05)`).
  ui.ImageFilter _lensFilter(ui.ImageFilter refraction) => ui.ImageFilter.compose(
    outer: ui.ImageFilter.matrix(_chainToneMatrix),
    inner: ui.ImageFilter.compose(
      outer: ui.ImageFilter.blur(
        sigmaX: _chainBlurSigma,
        sigmaY: _chainBlurSigma,
      ),
      inner: refraction,
    ),
  );

  @override
  Widget build(BuildContext context) {
    assert(() {
      GlassScope.debugAssertNotNested(context, 'LiquidGlass');
      return true;
    }(), 'LiquidGlass must not sit inside another glass surface');
    final theme = context.theme;
    _radius = _resolveRadius(context);
    final supportsRefraction = !widget.fallback && ui.ImageFilter.isShaderFilterSupported;
    // The refracting pane wears the clear variant's wash, edge and shine
    // (the web kit's `data-glass="clear"`). Where refraction cannot run and
    // no fallback was asked for, the pane frosts — the frost recipe's wash,
    // edge work and composed blur, like the web kit's non-Chromium path.
    // The explicit fallback resolves the solid card with the clear edge
    // work kept, the reduced-transparency treatment.
    final style = GlassSurfaceStyle.resolve(
      variant: widget.fallback || supportsRefraction ? GlassVariant.clear : GlassVariant.frost,
      theme: theme,
      radius: _radius,
      fallback: widget.fallback,
    );
    return GlassScope(
      child: DecoratedBox(
        decoration: BoxDecoration(borderRadius: _radius, boxShadow: style.shadows),
        child: ClipRRect(
          borderRadius: _radius,
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: supportsRefraction
                    ? FutureBuilder<LiquidGlassProgram>(
                        future: _program,
                        builder: (context, snapshot) {
                          final program = snapshot.data;
                          if (program == null) {
                            // Loading: the plain wash until the program is in.
                            return ColoredBox(color: style.wash);
                          }
                          _syncLens(program);
                          return BackdropFilter(
                            filter: _lensFilter(ui.ImageFilter.shader(_shader!)),
                            child: ColoredBox(color: style.wash),
                          );
                        },
                      )
                    : style.usesBackdropFilter
                    ? BackdropFilter(
                        filter: style.backdropFilter,
                        child: ColoredBox(color: style.wash),
                      )
                    // The solid card: no blur layer at all.
                    : ColoredBox(color: style.wash),
              ),
              Positioned.fill(
                child: CustomPaint(painter: GlassEdgePainter(style: style)),
              ),
              if (widget.padding != null)
                Padding(padding: widget.padding!, child: widget.child)
              else
                widget.child,
            ],
          ),
        ),
      ),
    );
  }

  /// Creates the pane's shader on first load, or re-applies the lens when a
  /// value moved. Runs inside the builder, so it only ever touches fields
  /// the same build consumes.
  void _syncLens(LiquidGlassProgram program) {
    final shader = _shader;
    if (shader == null) {
      _shader = program.newShader(
        radius: _radius.topLeft.x,
        edgeWidth: widget.edgeWidth,
        refraction: widget.refraction,
        dispersion: widget.dispersion,
        highlight: _rimHighlight,
      );
      return;
    }
    program.applyLens(
      shader,
      radius: _radius.topLeft.x,
      edgeWidth: widget.edgeWidth,
      refraction: widget.refraction,
      dispersion: widget.dispersion,
      highlight: _rimHighlight,
    );
  }
}
