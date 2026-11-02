import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/widgets/glass/glass_style.dart';

// The brand frosted panel: GlassPanel carries the glass.css recipe over
// whatever sits behind it (a photo, a colored page, video). The recipe lives
// in glass_style.dart; this file only stacks its layers and adds grain.
//
// Grain follows glass.css's data-grain: a seeded, tileable 160x160 noise
// image painted once per tile with BlendMode.overlay at 18% opacity. It is
// static (never animated, never re-seeded) so it cannot flicker, and it sits
// above the wash and below the content, like the CSS ::after.
//
// Do not put a GlassPanel inside another GlassPanel or GlassDock; GlassScope
// asserts against it in debug builds. For an entrance, fade the panel in
// with a FadeTransition — never animate the blur sigma.

/// A frosted glass panel (BRAND.md signature surfaces, glass.css
/// `data-slot="glass"`).
///
/// One BackdropFilter per panel composes blur and 1.5x saturation, clipped
/// tightly by a ClipRRect; the wash, border, gradient shine and shadows come
/// from the resolved [GlassSurfaceStyle]. Surfaces never nest, and nothing
/// moves on hover, press or focus.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    required this.child,
    this.variant = GlassVariant.frost,
    this.grain = false,
    this.padding,
    this.radius,
    this.fallback = false,
    super.key,
  });

  /// The panel's content, laid out inside [padding].
  final Widget child;

  /// How much glass the panel carries; frost by default.
  final GlassVariant variant;

  /// Whether to paint the seeded grain overlay (glass.css `data-grain`).
  final bool grain;

  /// Padding around [child]; none by default, like the CSS class.
  final EdgeInsetsGeometry? padding;

  /// Corner radius override; the theme's large radius (brand radius + 4) by
  /// default.
  final BorderRadius? radius;

  /// The honest degraded path: solid card fill, same border and shine, no
  /// blur layer at all. Flutter 3.44 has no reduced-transparency MediaQuery
  /// flag, so callers opt in when the platform or the user asks for it.
  final bool fallback;

  @override
  Widget build(BuildContext context) {
    assert(() {
      GlassScope.debugAssertNotNested(context, 'GlassPanel');
      return true;
    }(), 'GlassPanel must not sit inside another glass surface');
    final style = GlassSurfaceStyle.resolve(
      variant: variant,
      theme: context.theme,
      radius: radius,
      fallback: fallback,
    );
    return GlassScope(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: style.radius,
          boxShadow: style.shadows,
        ),
        child: ClipRRect(
          borderRadius: style.radius,
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: style.usesBackdropFilter
                    ? BackdropFilter(
                        filter: style.backdropFilter,
                        child: ColoredBox(color: style.wash),
                      )
                    : ColoredBox(color: style.wash),
              ),
              if (grain) const Positioned.fill(child: _GrainOverlay(seed: _grainSeed)),
              Positioned.fill(
                child: CustomPaint(painter: GlassEdgePainter(style: style)),
              ),
              if (padding != null) Padding(padding: padding!, child: child) else child,
            ],
          ),
        ),
      ),
    );
  }
}

/// The seed behind every panel's grain; one tile for the whole app so panels
/// with grain read as one material.
const int _grainSeed = 7;

/// Builds and caches the grain tile for a seed.
///
/// The tile lives for the app's lifetime (bounded by the number of distinct
/// seeds, which is one today), so it is never disposed.
final class _GrainTexture {
  _GrainTexture._();

  static final Map<int, ui.Image> _cache = <int, ui.Image>{};

  /// The tile for [seed], rendered once and cached; deterministic bytes, so
  /// the same seed always draws the same grain.
  ///
  /// Rendering is synchronous ([ui.Picture.toImageSync]): the CSS ::after is
  /// a paint-time asset, and an async decode would leave the panel grainless
  /// for its first frames — permanently under the fake-async pumps of tests
  /// and goldens, which never settle engine futures.
  static ui.Image load(int seed) {
    return _cache.putIfAbsent(seed, () => _render(seed));
  }

  static ui.Image _render(int seed) {
    const size = 160;
    final random = math.Random(seed);
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    // glass.css's feColorMatrix pins RGB at constant 0.5 grey and scales the
    // turbulence's alpha into the channel at 0.55. Constant mid-grey is the
    // neutral axis of the noise: every pixel shifts the backdrop toward the
    // same grey, so only the alpha varies.
    const grey = 128;
    final paint = Paint();
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        final alpha = (random.nextInt(256) * 0.55).round().clamp(0, 255);
        paint.color = ui.Color.fromARGB(alpha, grey, grey, grey);
        canvas.drawRect(Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1), paint);
      }
    }
    final image = recorder.endRecording().toImageSync(size, size);
    return image;
  }
}

/// Mounts the grain overlay, painting the cached tile immediately: the
/// decoder-free path means a panel is never shown without its grain.
class _GrainOverlay extends StatelessWidget {
  const _GrainOverlay({required this.seed});

  final int seed;

  @override
  Widget build(BuildContext context) {
    // The CSS ::after carries its 18% layer opacity on an alpha-only paint;
    // the foreground token stands in for Colors.black so every color in the
    // kit comes from the theme (an image draw reads only the paint's alpha).
    // Painted plain (SrcOver) rather than BlendMode.overlay: Skia composes
    // overlay on unpremultiplied colors, where a mid-grey source is pixel
    // identity — the grain would vanish. The browser's advanced blend runs
    // on premultiplied values, which reads as the same soft speckle a plain
    // grey-alpha draw gives: each noise pixel pulls the backdrop toward mid
    // grey by up to 18% of its 0.55-scaled alpha. Calibration stays with the
    // macOS capture join, like every other glass value.
    final tint = context.theme.colors.foreground.withValues(alpha: 0.18);
    return CustomPaint(
      painter: _GrainPainter(_GrainTexture.load(seed), tint),
    );
  }
}

class _GrainPainter extends CustomPainter {
  const _GrainPainter(this.tile, this.tint);

  final ui.Image tile;

  /// Token color carrying the 18% layer opacity. drawImageRect without a
  /// colorFilter uses only a paint's alpha, so the token's RGB never tints
  /// the grain.
  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = tint;
    final tileWidth = tile.width.toDouble();
    final tileHeight = tile.height.toDouble();
    final source = Rect.fromLTWH(0, 0, tileWidth, tileHeight);
    for (var x = 0.0; x < size.width; x += tileWidth) {
      for (var y = 0.0; y < size.height; y += tileHeight) {
        canvas.drawImageRect(
          tile,
          source,
          Rect.fromLTWH(x, y, tileWidth, tileHeight),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_GrainPainter oldDelegate) =>
      oldDelegate.tile != tile || oldDelegate.tint != tint;
}
