import 'dart:async' show unawaited;
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show SynchronousFuture;
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
  static Future<ui.Image> load(int seed) {
    final cached = _cache[seed];
    if (cached != null) {
      return SynchronousFuture<ui.Image>(cached);
    }
    return _render(seed).then((image) {
      _cache[seed] = image;
      return image;
    });
  }

  static Future<ui.Image> _render(int seed) async {
    const size = 160;
    final random = math.Random(seed);
    final bytes = Uint8List(size * size * 4);
    // glass.css's feColorMatrix pins RGB at constant 0.5 grey and scales the
    // turbulence's alpha into the channel at 0.55. Constant mid-grey is an
    // identity source under ideal overlay math; the grain the browser shows
    // comes from the blend running on premultiplied values, and Flutter's
    // BlendMode.overlay implements the same formula, so the recipe is ported
    // byte for byte rather than pre-varied. Calibration stays with the macOS
    // capture join, like every other glass value.
    const grey = 128;
    for (var i = 0; i < size * size; i++) {
      final alpha = (random.nextInt(256) * 0.55).round().clamp(0, 255);
      bytes[i * 4] = grey;
      bytes[i * 4 + 1] = grey;
      bytes[i * 4 + 2] = grey;
      bytes[i * 4 + 3] = alpha;
    }
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: size,
      height: size,
      pixelFormat: ui.PixelFormat.rgba8888,
    );
    final codec = await descriptor.instantiateCodec();
    final frame = await codec.getNextFrame();
    codec.dispose();
    descriptor.dispose();
    buffer.dispose();
    return frame.image;
  }
}

/// Mounts the grain overlay, painting nothing until the tile decodes.
class _GrainOverlay extends StatefulWidget {
  const _GrainOverlay({required this.seed});

  final int seed;

  @override
  State<_GrainOverlay> createState() => _GrainOverlayState();
}

class _GrainOverlayState extends State<_GrainOverlay> {
  ui.Image? _tile;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(_GrainOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seed != widget.seed) {
      _tile = null;
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    final tile = await _GrainTexture.load(widget.seed);
    if (mounted) {
      setState(() => _tile = tile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tile = _tile;
    if (tile == null) {
      return const SizedBox.expand();
    }
    // The CSS ::after carries its 18% layer opacity on an alpha-only paint;
    // the foreground token stands in for Colors.black so every color in the
    // kit comes from the theme (only the alpha channel reaches the image).
    final tint = context.theme.colors.foreground.withValues(alpha: 0.18);
    return CustomPaint(painter: _GrainPainter(tile, tint));
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
    final paint = Paint()
      ..blendMode = BlendMode.overlay
      ..color = tint;
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
