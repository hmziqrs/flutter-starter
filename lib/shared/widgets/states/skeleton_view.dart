import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/motion/app_motion.dart';

@immutable
class SkeletonStyle {
  const SkeletonStyle({
    required this.baseColor,
    required this.highlightColor,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  factory SkeletonStyle.of(BuildContext context) {
    final colors = context.theme.colors;
    final base = _lerp(colors.background, colors.foreground, 0.10);
    final highlight = _lerp(base, const Color(0xFFFFFFFF), 0.35);
    return SkeletonStyle(baseColor: base, highlightColor: highlight);
  }

  final Color baseColor;

  final Color highlightColor;

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

class _SkeletonShimmerScope extends InheritedWidget {
  const _SkeletonShimmerScope({
    required this.style,
    required this.animation,
    required this.textDirection,
    required super.child,
  });

  final SkeletonStyle style;

  final Animation<double>? animation;

  final TextDirection textDirection;

  @override
  bool updateShouldNotify(_SkeletonShimmerScope old) =>
      style != old.style || animation != old.animation || textDirection != old.textDirection;

  static _SkeletonShimmerScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SkeletonShimmerScope>();
}

class SkeletonView extends StatefulWidget {
  const SkeletonView({
    required this.child,
    this.style,
    this.semanticsLabel,
    super.key,
  });

  final Widget child;

  final SkeletonStyle? style;

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

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    this.width,
    this.height,
    this.borderRadius,
    super.key,
  });

  final double? width;

  final double? height;

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

class SkeletonLine extends StatelessWidget {
  const SkeletonLine({
    this.widthFraction = 1.0,
    this.fixedWidth,
    this.height = 12.0,
    this.borderRadius,
    super.key,
  });

  final double widthFraction;

  final double? fixedWidth;

  final double height;

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

class SkeletonCircle extends StatelessWidget {
  const SkeletonCircle({this.size = 32.0, super.key});

  final double size;

  @override
  Widget build(BuildContext context) => SkeletonBox(
    width: size,
    height: size,
    borderRadius: BorderRadius.all(Radius.circular(size / 2)),
  );
}

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
