import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/brand_tokens.dart';

/// A small ring for live status (the kits' `status-ring`): on carries a dot
/// round it, off is a faint full ring, stale is a broken ring in the muted
/// color. The word next to it carries the meaning; this only shows it.
///
/// The on state is the accent ring with three quarters drawn and a filled
/// dot riding its end, the pair turning once every 2.8 seconds; stale breaks
/// the ring into the kit's `3 4` dash in the muted foreground and never
/// turns; off draws the whole ring in the ring-art hairline. Reduced motion
/// holds the still picture. Decorative: pair it with a text label that
/// carries the meaning.
class StatusRing extends StatefulWidget {
  const StatusRing({
    required this.active,
    this.stale = false,
    this.size = 14,
    this.color,
    super.key,
  });

  /// Whether the thing the ring stands for is on.
  final bool active;

  /// Whether the thing is stale: a broken muted ring, neither on nor off.
  /// Wins over [active], like the kit's `data-state="stale"`.
  final bool stale;

  /// Square side of the ring; the kit draws it at `1em` — 14 beside `text-sm`
  /// labels, the common case.
  final double size;

  /// The on state's color; defaults to the theme's primary. The off state
  /// always draws the ring-art hairline, like the web kit's `--line`.
  final Color? color;

  @override
  State<StatusRing> createState() => _StatusRingState();
}

class _StatusRingState extends State<StatusRing> with SingleTickerProviderStateMixin {
  /// Seconds for one lap of the ring and its dot (`status-spin` in the kit).
  static const double _lapSeconds = 2.8;

  Ticker? _ticker;

  final ValueNotifier<double> _elapsed = ValueNotifier<double>(0);

  bool _reducedMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    _syncTicker();
  }

  @override
  void didUpdateWidget(StatusRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTicker();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _elapsed.dispose();
    super.dispose();
  }

  void _syncTicker() {
    if (_reducedMotion || !widget.active || widget.stale) {
      _ticker
        ?..stop()
        ..dispose();
      _ticker = null;
      if (_elapsed.value != 0) {
        _elapsed.value = 0;
      }
      return;
    }
    final ticker = _ticker ??= createTicker(_onTick);
    if (!ticker.isActive) {
      unawaited(ticker.start());
    }
  }

  void _onTick(Duration elapsed) {
    _elapsed.value = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: StatusRingPainter(
          active: widget.active,
          stale: widget.stale,
          color: widget.color ?? theme.colors.primary,
          lineColor: theme.brand.line,
          staleColor: theme.colors.mutedForeground,
          elapsed: _elapsed,
          repaint: _elapsed,
        ),
      ),
    );
  }
}

/// Paints the status ring in the kit's 20x20 viewBox: a ring of radius 7 at
/// stroke 1.75, and when on a dot of radius 2.4 at the ring's top.
///
/// On, the ring draws 33 of its ~44 circumference (the kit's `33 11` dash)
/// in [color] and the whole group rotates once every 2.8s, so the dot rides
/// round. Off, the ring draws whole in [lineColor] with no dot and no
/// rotation. Stale, the ring breaks into the kit's `3 4` dash in
/// [staleColor], no dot, no rotation.
class StatusRingPainter extends CustomPainter {
  StatusRingPainter({
    required this.active,
    required this.color,
    required this.lineColor,
    required this.staleColor,
    this.stale = false,
    ValueListenable<double>? elapsed,
    super.repaint,
  }) : _elapsed = elapsed ?? const _StillElapsed(0);

  /// The ring's radius in the 20x20 viewBox.
  static const double _radius = 7;

  /// The ring's stroke width in viewBox units.
  static const double _stroke = 1.75;

  /// The on state's dot radius in viewBox units.
  static const double _dotRadius = 2.4;

  /// The on state's drawn dash length (the kit's `stroke-dasharray: 33 11`).
  static const double _drawn = 33;

  /// The stale state's dash pattern (the kit's `stroke-dasharray: 3 4`).
  static const double _staleDash = 3;

  static const double _staleGap = 4;

  final bool active;

  final bool stale;

  final Color color;

  final Color lineColor;

  final Color staleColor;

  final ValueListenable<double> _elapsed;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 20;
    final center = size.center(Offset.zero);
    final radius = _radius * scale;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final spinning = active && !stale;
    final rotation = spinning ? _elapsed.value / _StatusRingState._lapSeconds : 0.0;
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke * scale
      ..strokeCap = StrokeCap.round
      ..color = stale ? staleColor : (active ? color : lineColor);
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..rotate(rotation * 2 * math.pi)
      ..translate(-center.dx, -center.dy);
    if (stale) {
      // The kit's broken ring: a `3 4` dash repeated round the circle.
      final circumference = 2 * math.pi * radius;
      final period = (_staleDash + _staleGap) * scale;
      for (var drawn = 0.0; drawn < circumference; drawn += period) {
        canvas.drawArc(
          rect,
          drawn / radius,
          math.min(_staleDash * scale, circumference - drawn) / radius,
          false,
          ringPaint,
        );
      }
    } else {
      canvas.drawArc(rect, 0, _drawn / _radius, false, ringPaint);
    }
    if (spinning) {
      // The dot rides the arc's end: the kit's cx=10 cy=3 sits at the ring's
      // top, the 270° end of the 0→270° dash, and turns with the group.
      canvas.drawCircle(
        Offset(center.dx, center.dy - radius),
        _dotRadius * scale,
        Paint()..color = color,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(StatusRingPainter oldDelegate) =>
      active != oldDelegate.active ||
      stale != oldDelegate.stale ||
      color != oldDelegate.color ||
      lineColor != oldDelegate.lineColor ||
      staleColor != oldDelegate.staleColor;
}

/// Holds a fixed elapsed time for still pictures.
final class _StillElapsed implements ValueListenable<double> {
  const _StillElapsed(this.value);

  @override
  final double value;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}
