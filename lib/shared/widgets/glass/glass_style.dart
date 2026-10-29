import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show immutable, listEquals;
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/fx/oklab.dart';

// The hmziq glass recipe, ported from brand-core glass.css
// ([data-slot="glass"], packages/brand-core/glass.css).
//
// Values: a CSS blur radius b maps to a Gaussian sigma of roughly b / 2, so
// frost (22px) becomes sigma 11, smoke (32px) sigma 16 and clear (12px)
// sigma 6. Verify the join visually at the macOS capture and adjust the
// sigmas there if a variant reads too strong, never per call site.
//
// The CSS saturate(1.5) is a hand-built matrix (Flutter has no
// ColorFilter.saturate) from the 0.213 / 0.715 / 0.072 luminance weights the
// CSS filter-effects spec defines saturate() with (Rec. 709).
//
// Renderer caveat: the default renderer on Flutter 3.44 is Impeller on macOS.
// Impeller improved blur in 3.38+ but BackdropFilter can still leave halos at
// panel edges, so every surface clips tightly with a ClipRRect. Check the
// join in the macOS capture; do not loosen the clip to hide a halo.
//
// Fallback: `fallback: true` renders the solid card variant (card fill, same
// border and shine, no blur), the honest degraded path glass.css uses for
// prefers-reduced-transparency. Flutter 3.44.7 exposes no
// reduced-transparency MediaQuery flag (checked against the framework
// source), so the explicit flag is the only trigger today.
//
// Discipline baked into this kit:
// - ONE BackdropFilter per surface: blur and saturation compose into a single
//   filter, never two stacked filters.
// - Glass never nests inside glass; GlassScope asserts this in debug builds.
// - Never animate sigma. Fade a surface in with a FadeTransition instead;
//   nothing here animates on hover, press or focus (BRAND.md s10).

/// How much glass a surface carries (glass.css `data-glass`).
enum GlassVariant {
  /// The default: blur sigma 11, a 64% background wash, foreground edges.
  frost,

  /// The heaviest: blur sigma 16 over an 80% wash, for overlays that must
  /// fully carry their content.
  smoke,

  /// The brand-tinted: 66% wash over a primary-mixed base, primary edge and
  /// shine. Use it where the surface means the brand, not for status.
  tint,

  /// The lightest: blur sigma 6 over a 34% wash, for labels and controls
  /// only. Read muted text as plain foreground inside it (glass.css remaps
  /// muted-foreground to foreground for this variant).
  clear,
}

/// The resolved glass recipe for one surface, derived from the ForUI theme.
///
/// Every color comes from the theme's tokens (BRAND.md s4); the numbers are
/// the glass.css recipe. Both GlassPanel and GlassDock build their layer
/// stack from this one style so they can never drift apart.
@immutable
final class GlassSurfaceStyle {
  const GlassSurfaceStyle({
    required this.blurSigma,
    required this.wash,
    required this.edge,
    required this.shine,
    required this.insetHighlight,
    required this.shadows,
    required this.radius,
  });

  /// Resolves the recipe for [variant] from [theme].
  ///
  /// [fallback] renders the solid card variant: card fill, the variant's
  /// border and shine kept, no blur. The default radius is the theme's large
  /// radius, which carries the brand radius plus 4 (glass.css
  /// `calc(var(--radius) + 4px)`; --radius is 10px, ForUI's lg is 14px).
  /// Every surface — panel and dock alike — carries exactly the two glass.css
  /// shadow lines; the brand dock is a plain glass pill with no extra depth.
  factory GlassSurfaceStyle.resolve({
    required GlassVariant variant,
    required FThemeData theme,
    BorderRadius? radius,
    bool fallback = false,
  }) {
    final colors = theme.colors;
    final background = colors.background;
    final foreground = colors.foreground;

    final (double cssBlur, double fill, Color washBase) = switch (variant) {
      GlassVariant.frost => (22, 0.64, background),
      GlassVariant.smoke => (32, 0.8, background),
      // glass.css mixes the tint wash in oklab
      // (`color-mix(in oklab, var(--primary) 16%, var(--background))`), so
      // the hue leans true orange instead of the sRGB lerp's muddier step.
      GlassVariant.tint => (22, 0.66, oklabMix(background, colors.primary, 0.16)),
      GlassVariant.clear => (12, 0.34, background),
    };

    final (Color edge, Color shine) = switch (variant) {
      GlassVariant.frost || GlassVariant.smoke => (
        foreground.withValues(alpha: 0.14),
        foreground.withValues(alpha: 0.22),
      ),
      GlassVariant.tint => (
        colors.primary.withValues(alpha: 0.3),
        colors.primary.withValues(alpha: 0.45),
      ),
      GlassVariant.clear => (
        foreground.withValues(alpha: 0.14),
        foreground.withValues(alpha: 0.3),
      ),
    };

    return GlassSurfaceStyle(
      blurSigma: fallback ? null : cssBlur / 2,
      wash: fallback ? colors.card : washBase.withValues(alpha: fill),
      edge: edge,
      shine: shine,
      insetHighlight: foreground.withValues(alpha: 0.1),
      shadows: <BoxShadow>[
        BoxShadow(
          color: background.withValues(alpha: 0.3),
          offset: const Offset(0, 1),
          blurRadius: 2,
        ),
        BoxShadow(
          color: background.withValues(alpha: 0.6),
          offset: const Offset(0, 24),
          blurRadius: 48,
          spreadRadius: -24,
        ),
      ],
      radius: radius ?? theme.style.borderRadius.lg,
    );
  }

  /// Gaussian sigma for the blur, or null in the fallback (no blur at all).
  ///
  /// Never animate this value; a sigma tween re-renders the blur every frame.
  final double? blurSigma;

  /// The translucent wash painted over the blurred backdrop, or the solid
  /// card color in the fallback.
  final Color wash;

  /// The 1px border color (glass.css `--glass-edge`).
  final Color edge;

  /// The gradient border shine color (glass.css `--glass-shine`).
  final Color shine;

  /// The 1px inset highlight along the top edge (glass.css's first
  /// box-shadow line; Flutter has no inset shadows, so the edge painter
  /// draws it).
  final Color insetHighlight;

  /// The outer shadows (glass.css box-shadow lines 2 and 3).
  final List<BoxShadow> shadows;

  /// The corner radius of the surface.
  final BorderRadius radius;

  /// Whether the surface carries a BackdropFilter at all.
  bool get usesBackdropFilter => blurSigma != null;

  /// The single composed backdrop filter: blur first, then 1.5x saturation
  /// (compose applies the inner filter first: `outer(inner(source))`).
  ///
  /// Null in the fallback, which must paint no blur layer.
  ui.ImageFilter? get backdropFilter => blurSigma == null
      ? null
      : ui.ImageFilter.compose(
          outer: ui.ImageFilter.matrix(saturationMatrix(1.5)),
          inner: ui.ImageFilter.blur(sigmaX: blurSigma!, sigmaY: blurSigma!),
        );

  /// The 160deg gradient border shine (glass.css `::before`), sampled over
  /// [rect]: shine at the top, clear through the middle, shine at half
  /// strength along the bottom.
  ui.Gradient shineGradient(Rect rect) {
    const angleDegrees = 160;
    const angle = angleDegrees * math.pi / 180;
    // CSS gradient angle: 0deg points up, clockwise; screen space is y-down.
    final direction = Offset(math.sin(angle), -math.cos(angle));
    final length = rect.width * direction.dx.abs() + rect.height * direction.dy.abs();
    final center = rect.center;
    final half = direction * (length / 2);
    return ui.Gradient.linear(
      center - half,
      center + half,
      <Color>[
        shine,
        shine.withValues(alpha: 0),
        shine.withValues(alpha: 0),
        shine.withValues(alpha: shine.a * 0.5),
      ],
      const <double>[0, 0.32, 0.68, 1],
    );
  }

  /// A 4x4 column-major saturation matrix equal to the CSS `saturate(s)`
  /// filter, built from the Rec. 709 luminance weights (0.213 / 0.715 /
  /// 0.072) the CSS filter-effects spec defines it with.
  ///
  /// Public so the liquid surface can fold its brighter 1.6x saturation (the
  /// web kit composes `saturate(1.6) brightness(1.05)` over the refraction)
  /// into one color matrix; the flat variants use 1.5 via [backdropFilter].
  static Float64List saturationMatrix(double saturation) {
    const redLuminance = 0.213;
    const greenLuminance = 0.715;
    const blueLuminance = 0.072;
    final red = (1 - saturation) * redLuminance;
    final green = (1 - saturation) * greenLuminance;
    final blue = (1 - saturation) * blueLuminance;
    return Float64List.fromList(<double>[
      red + saturation, red, red, 0, // column 0
      green, green + saturation, green, 0, // column 1
      blue, blue, blue + saturation, 0, // column 2
      0, 0, 0, 1, // column 3
    ]);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GlassSurfaceStyle &&
          runtimeType == other.runtimeType &&
          blurSigma == other.blurSigma &&
          wash == other.wash &&
          edge == other.edge &&
          shine == other.shine &&
          insetHighlight == other.insetHighlight &&
          listEquals(shadows, other.shadows) &&
          radius == other.radius;

  @override
  int get hashCode => Object.hash(
    blurSigma,
    wash,
    edge,
    shine,
    insetHighlight,
    Object.hashAll(shadows),
    radius,
  );
}

/// Paints the surface's border work: the 1px inset top highlight, the 1px
/// solid edge, and the 160deg gradient shine ring on top of it.
///
/// The painter draws only strokes, so it never blocks hit testing.
class GlassEdgePainter extends CustomPainter {
  const GlassEdgePainter({required this.style});

  /// The resolved recipe whose colors this painter strokes.
  final GlassSurfaceStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = style.radius.toRRect(rect);
    // The border strokes paint on a rrect pulled 0.5px inside the boundary,
    // so a 1px centered stroke lands exactly on the CSS border-box band
    // ([0, 1] inward) and survives the panel's ClipRRect, which would shave
    // the outer half off a boundary-centered stroke.
    final fitsBorderBand = rect.width > 1 && rect.height > 1;
    final borderRect = fitsBorderBand ? rect.deflate(0.5) : rect;
    final borderRrect = fitsBorderBand ? style.radius.toRRect(borderRect) : rrect;

    // Inset top highlight: the first glass.css box-shadow line, drawn by hand
    // because Flutter has no inset shadows. Clipped to the corners.
    canvas
      ..save()
      ..clipRRect(rrect)
      ..drawRect(
        Rect.fromLTWH(rect.left, rect.top, rect.width, 1),
        Paint()..color = style.insetHighlight,
      )
      ..restore()
      ..drawRRect(
        borderRrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = style.edge,
      )
      // The 160deg shine rides the same band, over the edge, exactly like the
      // masked ::before ring reads once the browser composites it (the CSS
      // ring sits in the 1px outside the border box, which the panel clip
      // cannot show; the border band is the honest in-clip stand-in).
      ..drawRRect(
        borderRrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..shader = style.shineGradient(borderRect),
      );
  }

  @override
  bool shouldRepaint(GlassEdgePainter oldDelegate) => oldDelegate.style != style;
}

/// Marks a glass surface's subtree so nested surfaces fail fast.
///
/// GlassPanel and GlassDock insert one and assert in debug builds that
/// no ancestor already provided it: glass inside glass stacks blur on blur
/// and reads as mush. Release builds skip the check entirely.
class GlassScope extends InheritedWidget {
  const GlassScope({required super.child, super.key});

  static GlassScope? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<GlassScope>();

  /// Throws a descriptive [FlutterError] when [context] sits inside another
  /// glass surface. Call from an assert only.
  static void debugAssertNotNested(BuildContext context, String surfaceName) {
    if (maybeOf(context) != null) {
      throw FlutterError(
        '$surfaceName is nested inside another glass surface. Glass never '
        'nests inside glass: one BackdropFilter per surface, and a surface '
        'is never placed inside another one. Move the inner surface out, or '
        'let the outer one carry the content.',
      );
    }
  }

  @override
  bool updateShouldNotify(GlassScope oldWidget) => false;
}
