import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';

/// The stock skeleton's animate-pulse timing: a 2s cycle on
/// cubic-bezier(0.4, 0, 0.6, 1), easing each opacity half separately.
const _pulseDuration = Duration(milliseconds: 2000);
const _pulseCurve = Cubic(0.4, 0, 0.6, 1);

@immutable
class SkeletonStyle {
  const SkeletonStyle({
    required this.baseColor,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  factory SkeletonStyle.of(BuildContext context) {
    final colors = context.theme.colors;
    return SkeletonStyle(
      // The stock skeleton's `bg-muted` (ui/skeleton/skeleton.svelte).
      baseColor: colors.muted,
      borderRadius: context.theme.style.borderRadius.sm,
    );
  }

  final Color baseColor;

  final BorderRadius borderRadius;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SkeletonStyle && baseColor == other.baseColor && borderRadius == other.borderRadius;

  @override
  int get hashCode => Object.hash(baseColor, borderRadius);
}

class _SkeletonPulseScope extends InheritedWidget {
  const _SkeletonPulseScope({
    required this.style,
    required this.animation,
    required this.textDirection,
    required super.child,
  });

  final SkeletonStyle style;

  /// Drives the bone's opacity through the pulse; null under reduced motion.
  final Animation<double>? animation;

  final TextDirection textDirection;

  @override
  bool updateShouldNotify(_SkeletonPulseScope old) =>
      style != old.style || animation != old.animation || textDirection != old.textDirection;

  static _SkeletonPulseScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SkeletonPulseScope>();
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
      // The stock skeleton's animate-pulse: opacity 1 -> 0.5 -> 1 over the
      // 2s cycle with the tailwind easing per half, paused entirely under
      // reduced motion (motion-reduce:animate-none).
      final controller = AnimationController(vsync: this, duration: _pulseDuration);
      unawaited(controller.repeat(reverse: true));
      _controller = controller;
      _animation = Tween<double>(
        begin: 1,
        end: 0.5,
      ).animate(CurvedAnimation(parent: controller, curve: _pulseCurve));
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
    return _SkeletonPulseScope(
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
    final scope = _SkeletonPulseScope.of(context);
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

  /// The pulse's opacity for this frame; null paints the static bone.
  final Animation<double>? animation;

  late final Paint _bonePaint = Paint()..color = style.baseColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect);

    final opacity = animation?.value ?? 1;
    canvas.drawRRect(rrect, _bonePaint..color = style.baseColor.withValues(alpha: opacity));
  }

  @override
  bool shouldRepaint(covariant _BonePainter old) =>
      style.baseColor != old.style.baseColor ||
      borderRadius != old.borderRadius ||
      textDirection != old.textDirection ||
      animation != old.animation;
}
