import 'dart:ui' as ui show FragmentShader, ImageFilter;

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/fx/shaders/liquid_glass_program.dart';
import 'package:starter/shared/widgets/glass/glass_style.dart';

// Liquid glass: the web kit's SVG displacement-map refraction, ported as an
// ImageFilter.shader backdrop filter (assets/shaders/liquid_glass.frag). The
// shader bends the backdrop along the pane's rounded-rect normal, strongest
// at the rim, and adds the thin rim highlight; the wash, edge and shine come
// from the same GlassSurfaceStyle resolve the flat variants use, so the
// surface still reads as the one glass family.
//
// Engine discipline: ImageFilter.shader exists only under Impeller, and
// flutter test runs on Skia, so the widget checks
// ImageFilter.isShaderFilterSupported and renders the solid glass card — the
// same honest degraded path as the fallback — while the program loads or
// where the filter is unsupported.
//
// Glass rules carry over unchanged: ONE filter per surface, never nested
// (GlassScope asserts), never animated (BRAND.md s10).

/// A liquid glass panel (BRAND.md signature surfaces): content over a
/// refracted backdrop in a rounded pane.
///
/// The lens defaults give a calm rim bend; tune [refraction], [dispersion]
/// and [edgeWidth] per surface, never per platform. The shader models one
/// corner radius (the pane's top-start value), so pass a uniform [radius].
class LiquidGlass extends StatefulWidget {
  const LiquidGlass({
    required this.child,
    this.padding,
    this.radius,
    this.refraction = 12,
    this.dispersion = 3,
    this.edgeWidth = 24,
    this.fallback = false,
    super.key,
  });

  /// The panel's content, laid out inside [padding].
  final Widget child;

  /// Padding around [child].
  final EdgeInsetsGeometry? padding;

  /// Corner radius override; the theme's large radius by default.
  final BorderRadius? radius;

  /// Rim displacement at the very edge, in px.
  final double refraction;

  /// Per-channel spread of the rim refraction, in px (the chromatic fringe).
  final double dispersion;

  /// How far inland the bend reaches, in px.
  final double edgeWidth;

  /// The honest degraded path: solid card fill, same border and shine, no
  /// refraction at all.
  final bool fallback;

  @override
  State<LiquidGlass> createState() => _LiquidGlassState();
}

class _LiquidGlassState extends State<LiquidGlass> {
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

  @override
  Widget build(BuildContext context) {
    assert(() {
      GlassScope.debugAssertNotNested(context, 'LiquidGlass');
      return true;
    }(), 'LiquidGlass must not sit inside another glass surface');
    final theme = context.theme;
    _radius = _resolveRadius(context);
    // The clear variant's wash, edge and shine; only the fill differs per
    // path, and the painter only reads the edge work.
    final style = GlassSurfaceStyle.resolve(
      variant: GlassVariant.clear,
      theme: theme,
      radius: _radius,
    );
    final supportsRefraction = !widget.fallback && ui.ImageFilter.isShaderFilterSupported;
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
                            filter: ui.ImageFilter.shader(_shader!),
                            child: ColoredBox(color: style.wash),
                          );
                        },
                      )
                    // The honest degraded path: solid card fill, same border
                    // and shine, no refraction at all.
                    : ColoredBox(color: theme.colors.card),
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
