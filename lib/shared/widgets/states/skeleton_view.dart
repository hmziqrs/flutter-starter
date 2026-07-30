import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/motion/app_motion.dart';

/// Visual style for skeleton bones, derived from the active ForUI theme so
/// bones match the active brightness. [highlightColor] is always perceptually
/// lighter than [baseColor] so the shimmer sweep reads in both themes.
@immutable
class SkeletonStyle {
  /// Creates a [SkeletonStyle].
  const SkeletonStyle({
    required this.baseColor,
    required this.highlightColor,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  /// Builds a style from the active ForUI theme colors.
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
/// descendant bones. When [animation] is `null` (reduce-motion, goldens, or
/// standalone bone use) the bones paint their static base fill only.
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

/// Wraps a laid-out subtree of skeleton bones ([SkeletonBox], [SkeletonLine],
/// [SkeletonCircle], and the SkeletonTile/SkeletonCard composites in
/// `skeleton_tile.dart`) and drives the shared shimmer.
///
/// When `MediaQuery.disableAnimationsOf(context)` is true (reduce-motion or a
/// golden harness) no ticker runs and the bones paint their static base fill;
/// the subtree still lays out but never animates.
///
/// Tests must use bounded frame pumps, never `pumpAndSettle` — the repeating
/// shimmer would otherwise hang the harness.
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
        duration: AppMotion.deliberate * 3,
      );
      unawaited(controller.repeat());
      _controller = controller;
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
/// is driving a shimmer animation, overlays the moving highlight sweep.
/// Otherwise paints the static base fill only.
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

/// A skeleton bone shaped like a single line of text: a [SkeletonBox] whose
/// width is a [widthFraction] of the available width, or a [fixedWidth].
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

/// A circular skeleton bone (avatar / leading icon placeholder): a
/// [SkeletonBox] with equal width/height and a fully rounded radius.
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

    canvas.drawRRect(rrect, Paint()..color = style.baseColor);

    final progress = animation?.value;
    if (progress == null) return;

    final w = rect.width;
    if (w <= 0 || rect.height <= 0) return;
    // Virtual rect 3x as wide, sliding fully-left to fully-right, so the
    // highlight band enters and exits the edges seamlessly.
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
