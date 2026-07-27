import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/motion/app_motion.dart';

/// Typed visual style for skeleton bones.
///
/// Derives its colors from the surrounding ForUI theme so bones match the
/// active brightness (light/dark). The [baseColor] fills a bone; the
/// [highlightColor] is the shimmer sweep and is always perceptually lighter
/// than [baseColor] so the sweep reads in both themes. Immutable value object:
/// typed fields only, no `dynamic`, value-equality for cheap
/// [InheritedWidget] comparisons.
@immutable
class SkeletonStyle {
  /// Creates a [SkeletonStyle].
  const SkeletonStyle({
    required this.baseColor,
    required this.highlightColor,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  /// Builds a style from the active ForUI theme colors.
  ///
  /// The bone base is a faint tint of the theme foreground on the theme
  /// background (a neutral gray in both light and dark); the highlight is the
  /// base lifted toward white so the sweep is always brighter than the bone
  /// and stays visible under either brightness.
  factory SkeletonStyle.of(BuildContext context) {
    final colors = context.theme.colors;
    final base = _lerp(colors.background, colors.foreground, 0.10);
    final highlight = _lerp(base, const Color(0xFFFFFFFF), 0.35);
    return SkeletonStyle(baseColor: base, highlightColor: highlight);
  }

  /// Bone fill.
  final Color baseColor;

  /// Shimmer sweep color (lighter than [baseColor]).
  final Color highlightColor;

  /// Default bone corner radius.
  final BorderRadius borderRadius;

  /// Lerps [a] toward [b] by [t], never returning `null` (strict analysis:
  /// [Color.lerp] is nullable).
  static Color _lerp(Color a, Color b, double t) => Color.lerp(a, b, t) ?? a;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SkeletonStyle &&
          baseColor == other.baseColor &&
          highlightColor == other.highlightColor &&
          borderRadius == other.borderRadius;

  @override
  int get hashCode => Object.hash(baseColor, highlightColor, borderRadius);
}

/// An inherited scope exposing the active shimmer animation and style to
/// descendant bones.
///
/// When [animation] is `null` (reduce-motion, goldens, or standalone bone use)
/// the bones paint their static base fill only — the deterministic path.
class _SkeletonShimmerScope extends InheritedWidget {
  const _SkeletonShimmerScope({
    required this.style,
    required this.animation,
    required this.textDirection,
    required super.child,
  });

  final SkeletonStyle style;

  /// The shimmer progress (`0.0..1.0`). `null` selects the static path.
  final Animation<double>? animation;

  final TextDirection textDirection;

  @override
  bool updateShouldNotify(_SkeletonShimmerScope old) =>
      style != old.style || animation != old.animation || textDirection != old.textDirection;

  static _SkeletonShimmerScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SkeletonShimmerScope>();
}

/// Wraps a laid-out subtree of skeleton bones and drives the shared shimmer.
///
/// The [child] is a mirrored skeleton layout built from bone primitives
/// ([SkeletonBox], [SkeletonLine], [SkeletonCircle], plus the SkeletonTile /
/// SkeletonCard composites in `skeleton_tile.dart`). This widget sources the
/// shimmer duration/curve from [AppMotion] tokens and is motion-guarded (audit
/// checklist #5): when
/// `MediaQuery.disableAnimationsOf(context)` is true (reduce-motion or a golden
/// harness) no ticker runs and the bones paint their static base fill — the
/// subtree still lays out and is measurable, but never animates. Critical: the
/// shimmer is named explicitly by the motion checklist.
///
/// Backend-free (no port): the skeleton renders whenever a feature's
/// `*_presentation_state.isLoading` is true; no plugin, no network call, no
/// side effect. The skeleton itself carries no copy — the accessible loading
/// label reuses `states.loadingTitle` (state-views bucket) and can be
/// overridden via [semanticsLabel].
///
/// Tests must use bounded frame pumps (8 frames), never `pumpAndSettle` — the
/// repeating shimmer would otherwise hang the harness.
class SkeletonView extends StatefulWidget {
  /// Creates a [SkeletonView].
  const SkeletonView({
    required this.child,
    this.style,
    this.semanticsLabel,
    super.key,
  });

  /// The mirrored skeleton layout. Built from bone primitives so its shape
  /// tracks the production widget that will replace it.
  final Widget child;

  /// Optional style override. Defaults to [SkeletonStyle.of].
  final SkeletonStyle? style;

  /// Accessibility label applied to the shimmering region. Defaults to
  /// `states.loadingTitle`.
  final String? semanticsLabel;

  @override
  State<SkeletonView> createState() => _SkeletonViewState();
}

class _SkeletonViewState extends State<SkeletonView> with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _animation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync(reduceMotion: MediaQuery.disableAnimationsOf(context));
  }

  void _sync({required bool reduceMotion}) {
    if (reduceMotion) {
      _disposeController();
      return;
    }
    if (_controller == null) {
      final controller = AnimationController(
        vsync: this,
        // AppMotion-derived: a deliberate ~1.1s sweep period.
        duration: AppMotion.deliberate * 3,
      );
      unawaited(controller.repeat());
      _controller = controller;
      // emphasizedCurve is ease-in-out (symmetric) so the loop is seamless:
      // both endpoints settle with the highlight band off-edge.
      _animation = controller.drive(CurveTween(curve: AppMotion.emphasizedCurve));
    }
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
    _animation = null;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? SkeletonStyle.of(context);
    final label = widget.semanticsLabel ?? context.t.states.loadingTitle;
    return _SkeletonShimmerScope(
      style: style,
      animation: _animation,
      textDirection: Directionality.of(context),
      child: Semantics(
        label: label,
        container: true,
        button: false,
        child: widget.child,
      ),
    );
  }
}

/// A rounded-rect skeleton bone.
///
/// Fills with [SkeletonStyle.baseColor] and, when an ancestor [SkeletonView]
/// is driving a shimmer animation, overlays the moving highlight sweep. With no
/// ancestor scope (standalone use) or under reduce-motion it paints the static
/// base fill only — fully deterministic for goldens. Reads colors from
/// `context.theme` (audit checklist: colors derive from theme).
class SkeletonBox extends StatelessWidget {
  /// Creates a [SkeletonBox].
  const SkeletonBox({
    this.width,
    this.height,
    this.borderRadius,
    super.key,
  });

  /// Bone width. `null` fills the available width.
  final double? width;

  /// Bone height. `null` fills the available height.
  final double? height;

  /// Corner radius. Defaults to [SkeletonStyle.borderRadius].
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final scope = _SkeletonShimmerScope.of(context);
    final style = scope?.style ?? SkeletonStyle.of(context);
    final radius = borderRadius ?? style.borderRadius;
    final animation = scope?.animation;
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _BonePainter(
          style: style,
          borderRadius: radius,
          textDirection: scope?.textDirection ?? Directionality.of(context),
          animation: animation,
        ),
      ),
    );
  }
}

/// A skeleton bone shaped like a single line of text.
///
/// Renders a [SkeletonBox] whose width is a [widthFraction] of the available
/// width (start-aligned, RTL-aware), or a [fixedWidth] when provided. Stacks of
/// [SkeletonLine] mirror paragraph text while data loads.
class SkeletonLine extends StatelessWidget {
  /// Creates a [SkeletonLine].
  const SkeletonLine({
    this.widthFraction = 1.0,
    this.fixedWidth,
    this.height = 12.0,
    this.borderRadius,
    super.key,
  });

  /// Width as a fraction of the available width in `0.0..1.0`. Ignored when
  /// [fixedWidth] is non-null.
  final double widthFraction;

  /// Fixed width in logical pixels. When non-null this takes precedence over
  /// [widthFraction].
  final double? fixedWidth;

  /// Line thickness in logical pixels.
  final double height;

  /// Corner radius override.
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    if (fixedWidth != null) {
      return SkeletonBox(
        width: fixedWidth,
        height: height,
        borderRadius: borderRadius,
      );
    }
    // Manual clamp avoids the `num` widening that `double.clamp` can trigger
    // under strict analysis (mirrors BusyIndicator).
    var fraction = widthFraction;
    if (fraction < 0) fraction = 0;
    if (fraction > 1) fraction = 1;
    return FractionallySizedBox(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: fraction,
      child: SkeletonBox(height: height, borderRadius: borderRadius),
    );
  }
}

/// A circular skeleton bone (avatar / leading icon placeholder).
///
/// Equivalent to a [SkeletonBox] with equal width/height and a fully rounded
/// radius; inherits the ancestor shimmer or the static reduce-motion fill.
class SkeletonCircle extends StatelessWidget {
  /// Creates a [SkeletonCircle].
  const SkeletonCircle({this.size = 32.0, super.key});

  /// Diameter in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) => SkeletonBox(
    width: size,
    height: size,
    borderRadius: BorderRadius.all(Radius.circular(size / 2)),
  );
}

/// Paints a single bone: the base fill plus an optional moving highlight band.
///
/// The shimmer slides a 3-stop [LinearGradient] (base → highlight → base) across
/// a virtual rect wider than the bone so the bright band enters and exits the
/// edges; under RTL the gradient is mirrored so the sweep reads right-to-left.
class _BonePainter extends CustomPainter {
  _BonePainter({
    required this.style,
    required this.borderRadius,
    required this.textDirection,
    this.animation,
  }) : super(repaint: animation);

  final SkeletonStyle style;
  final BorderRadius borderRadius;
  final TextDirection textDirection;
  final Animation<double>? animation;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect);

    // Static base fill — always present (reduce-motion / golden path).
    canvas.drawRRect(rrect, Paint()..color = style.baseColor);

    final progress = animation?.value;
    if (progress == null) return; // Static path stops here.

    final w = rect.width;
    if (w <= 0 || rect.height <= 0) return;
    // Virtual rect 3x as wide; the bright band sits in its middle third. The
    // virtual rect slides from fully-left (band off the left edge) at t=0 to
    // fully-right (band off the right edge) at t=1, so the sweep is seamless.
    final virtual = Rect.fromLTWH(
      rect.left - 2 * w + progress * 2 * w,
      rect.top,
      3 * w,
      rect.height,
    );
    final gradient = LinearGradient(
      colors: <Color>[
        style.baseColor,
        style.highlightColor,
        style.baseColor,
      ],
      stops: const <double>[0.4, 0.5, 0.6],
    );
    final paint = Paint()..shader = gradient.createShader(virtual, textDirection: textDirection);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _BonePainter old) =>
      style.baseColor != old.style.baseColor ||
      style.highlightColor != old.style.highlightColor ||
      borderRadius != old.borderRadius ||
      textDirection != old.textDirection ||
      animation != old.animation;
}
