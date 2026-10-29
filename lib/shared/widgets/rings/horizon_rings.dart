import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/brand_tokens.dart';
import 'package:starter/shared/widgets/rings/brand_seed.dart';
import 'package:starter/shared/widgets/rings/ring_motion.dart' show ringPhase;

/// Seconds from one ripple wave to the next (`horizon-ripple` in the kits).
const double _rippleSeconds = 7;

/// Seconds between one ring's ripple and the ring outside it.
const double _rippleRingDelay = 0.14;

/// The horizon rings picture (the kits' `horizon-rings` component): half
/// rings rising from a horizon around a sun, drawn from [horizonArcs] and
/// [horizonStars] so the same seed always draws the same picture.
///
/// All measures are in the 600x320 viewBox and scale together with the box.
/// [awakeMix] fades the whole palette from the asleep state (sun out, stars
/// up) to awake (sun in primary) over its 0..1 value, matching the web's
/// 0.8s color transition. [reveal] (0..1) fades pieces in one after another
/// — sun first, rings outwards, then glints and stars — for scroll-linked
/// reveals; 1 draws everything. When `ripple` is on, the faint rings light
/// up in a wave toward the primary at 85% and back, `elapsed` seconds in.
class HorizonRingsPainter extends CustomPainter {
  HorizonRingsPainter({
    required this.arcs,
    required this.stars,
    required this.lineColor,
    required this.accentColor,
    required this.foregroundColor,
    this.awakeMix = 1,
    this.reveal = 1,
    this.ripple = false,
    ValueListenable<double>? elapsed,
    ValueListenable<double>? revealListenable,
    super.repaint,
  }) : _elapsed = elapsed ?? const _StillElapsed(0),
       _reveal = revealListenable;

  /// The picture's half rings, in viewBox units.
  final List<HorizonArc> arcs;

  /// The picture's stars, in viewBox units.
  final List<(Offset, double)> stars;

  /// The hairline color: the text color at 22%.
  final Color lineColor;

  /// The primary color the sun and the ripple light up in.
  final Color accentColor;

  /// The text color for the horizon line and the stars.
  final Color foregroundColor;

  /// 0 = asleep (sun out, stars up), 1 = awake (sun in primary).
  final double awakeMix;

  /// 0 = nothing drawn yet, 1 = everything; pieces fade in one by one.
  final double reveal;

  /// Overrides [reveal] with a live value; read at paint time so scroll
  /// repaints without rebuilding.
  final ValueListenable<double>? _reveal;

  /// Whether the faint rings light up in a wave while awake.
  final bool ripple;

  final ValueListenable<double> _elapsed;

  static const Size viewBox = Size(600, 320);
  static const Offset center = Offset(300, 262);
  static const double _sunRadius = 30;

  /// Fade-in window per piece of the picture.
  static const double _revealWindow = 0.1;

  /// The reveal value the painter will use next, for tests.
  @visibleForTesting
  double get revealValue => _reveal?.value ?? reveal;

  double _fade(double threshold, double share) =>
      ((revealValue - threshold) / _revealWindow).clamp(0.0, 1.0) * share;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / viewBox.width;
    final elapsed = _elapsed.value;
    canvas
      ..save()
      ..clipRect(Offset.zero & size)
      ..scale(scale);

    // The sky: a radial glow of primary around the sun, awake only.
    final skyAlpha = _fade(0, awakeMix);
    if (skyAlpha > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, viewBox.width, center.dy),
        Paint()
          ..shader = ui.Gradient.radial(
            center,
            230,
            <Color>[
              accentColor.withValues(alpha: 0.45 * skyAlpha),
              accentColor.withValues(alpha: 0.12 * skyAlpha),
              accentColor.withValues(alpha: 0),
            ],
            <double>[0, 0.45, 1],
          ),
      );
    }

    // Stars: out when asleep, gone when awake.
    final starAlpha = _fade(0.85, 0.55 * (1 - awakeMix));
    if (starAlpha > 0) {
      final starPaint = Paint()..color = foregroundColor.withValues(alpha: starAlpha);
      for (final (position, radius) in stars) {
        canvas.drawCircle(position, radius, starPaint);
      }
    }

    for (final (index, arc) in arcs.indexed) {
      final fade = _fade(0.06 + index * 0.075, 1);
      if (fade <= 0) {
        continue;
      }
      final rect = Rect.fromCircle(center: center, radius: arc.radius);
      Color color;
      if (arc.accent) {
        color = Color.lerp(lineColor, accentColor, awakeMix)!;
      } else if (ripple && awakeMix > 0) {
        final lit = accentColor.withValues(alpha: 0.85);
        // 0%, 22%, 100% at line; 10% lit; linear; one ring 0.14s later.
        final wave = ringRippleWave(elapsed, index * _rippleRingDelay);
        color = Color.lerp(lineColor, lit, wave)!;
      } else {
        color = lineColor;
      }
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = arc.accent ? 2.5 : 1.25
        ..color = color.withValues(alpha: color.a * fade);
      for (final (start, sweep) in arc.segments) {
        canvas.drawArc(rect, start, sweep, false, paint);
      }
      final end = arc.end;
      if (end != null) {
        final dot = Color.lerp(lineColor, accentColor, awakeMix)!;
        canvas.drawCircle(end, 5.5, Paint()..color = dot.withValues(alpha: dot.a * fade));
      }
    }

    // The sun: a half disc sitting on the horizon.
    final sunFade = _fade(0, 1);
    if (sunFade > 0) {
      final sunStroke = Color.lerp(lineColor, accentColor, awakeMix)!;
      final sunPath = Path()
        ..moveTo(center.dx - _sunRadius, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: _sunRadius),
          math.pi,
          math.pi,
          false,
        )
        ..close();
      canvas
        ..drawPath(
          sunPath,
          Paint()
            ..style = PaintingStyle.fill
            ..color = accentColor.withValues(alpha: awakeMix * sunFade),
        )
        ..drawPath(
          sunPath,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round
            ..color = sunStroke.withValues(alpha: sunStroke.a * sunFade),
        );
    }

    // The horizon line.
    final horizon = foregroundColor.withValues(alpha: 0.35 * _fade(0, 1));
    canvas.drawLine(
      Offset(16, center.dy),
      Offset(584, center.dy),
      Paint()
        ..strokeWidth = 1
        ..color = horizon,
    );

    // Glints under the horizon, biggest first.
    for (var i = 0; i < 4; i += 1) {
      final width = const <double>[64, 44, 28, 14][i];
      final fade = _fade(0.78 + i * 0.05, 1);
      if (fade <= 0) {
        continue;
      }
      final color = Color.lerp(lineColor, accentColor, awakeMix)!;
      final opacity = 0.6 + (0.7 - i * 0.15 - 0.6) * awakeMix;
      canvas.drawLine(
        Offset(center.dx - width, center.dy + 12 + i * 10),
        Offset(center.dx + width, center.dy + 12 + i * 10),
        Paint()
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: color.a * opacity * fade),
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(HorizonRingsPainter oldDelegate) =>
      arcs != oldDelegate.arcs ||
      stars != oldDelegate.stars ||
      lineColor != oldDelegate.lineColor ||
      accentColor != oldDelegate.accentColor ||
      foregroundColor != oldDelegate.foregroundColor ||
      awakeMix != oldDelegate.awakeMix ||
      reveal != oldDelegate.reveal ||
      ripple != oldDelegate.ripple;
}

/// The horizon ripple's wave position (0..1) for one ring [delay] seconds
/// in: linear, peaking 10% into the 7s cycle and done by 22%.
double ringRippleWave(double elapsedSeconds, double delay) {
  final position = ringPhase(elapsedSeconds, _rippleSeconds, delay);
  const peak = 0.10;
  const settled = 0.22;
  if (position <= peak) {
    return position / peak;
  }
  if (position <= settled) {
    return 1 - (position - peak) / (settled - peak);
  }
  return 0;
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

/// Half rings rising from a horizon around a sun in the accent color.
///
/// The same [HorizonRings.seed] always draws the same picture. Asleep, the
/// sun goes out and a few stars come up; the switch fades the colors over
/// 0.8s. With [HorizonRings.ripple], light runs out through the rings every
/// few seconds while awake — paused stops it, reduced motion stills it, and
/// TickerMode stops it off screen. Decorative: pass [HorizonRings
/// .semanticsLabel] to describe the picture, otherwise it is excluded from
/// semantics.
class HorizonRings extends StatefulWidget {
  const HorizonRings({
    required this.seed,
    this.awake = true,
    this.ripple = false,
    this.paused = false,
    this.semanticsLabel,
    super.key,
  });

  /// The site's or project's name.
  final String seed;

  /// Whether the sun is up; asleep, the sun goes out and stars come up.
  final bool awake;

  /// Light running out through the rings every few seconds while awake.
  final bool ripple;

  /// Stops the ripple where it is.
  final bool paused;

  /// What the picture shows, for screen readers.
  final String? semanticsLabel;

  @override
  State<HorizonRings> createState() => _HorizonRingsState();
}

class _HorizonRingsState extends State<HorizonRings> with TickerProviderStateMixin {
  static const Duration _transition = Duration(milliseconds: 800);

  AnimationController? _awake;

  Ticker? _rippleTicker;

  final ValueNotifier<double> _elapsed = ValueNotifier<double>(0);

  late List<HorizonArc> _arcs;

  late List<(Offset, double)> _stars;

  bool _reducedMotion = false;

  @override
  void initState() {
    super.initState();
    _draw();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    _ensureAwake();
    _syncRipple();
  }

  /// Reduced motion jumps straight to the target state with no duration.
  void _ensureAwake() {
    final controller = _awake ??= AnimationController(
      vsync: this,
      value: widget.awake ? 1 : 0,
    );
    unawaited(
      controller.animateTo(
        widget.awake ? 1 : 0,
        duration: _reducedMotion ? Duration.zero : _transition,
      ),
    );
  }

  @override
  void didUpdateWidget(HorizonRings oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seed != widget.seed) {
      _draw();
    }
    _ensureAwake();
    _syncRipple();
  }

  bool get _shouldRipple => !_reducedMotion && !widget.paused && widget.ripple && widget.awake;

  void _syncRipple() {
    if (_shouldRipple) {
      final ticker = _rippleTicker ??= createTicker(_onTick);
      if (!ticker.isActive) {
        unawaited(ticker.start());
      }
    } else {
      _rippleTicker
        ?..stop()
        ..dispose();
      _rippleTicker = null;
      if (_elapsed.value != 0) {
        _elapsed.value = 0;
      }
    }
  }

  void _onTick(Duration elapsed) {
    _elapsed.value = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
  }

  void _draw() {
    _arcs = horizonArcs(
      widget.seed,
      cx: HorizonRingsPainter.center.dx,
      cy: HorizonRingsPainter.center.dy,
      radii: <double>[for (var i = 0; i < 10; i += 1) 46.0 + 24 * i],
      accent: 2,
    );
    _stars = horizonStars(widget.seed);
  }

  @override
  void dispose() {
    _rippleTicker?.dispose();
    _awake?.dispose();
    _elapsed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final awake = _awake!;
    Widget picture = AnimatedBuilder(
      animation: awake,
      builder: (context, child) => CustomPaint(
        painter: HorizonRingsPainter(
          arcs: _arcs,
          stars: _stars,
          lineColor: theme.brand.line,
          accentColor: theme.colors.primary,
          foregroundColor: theme.colors.foreground,
          awakeMix: awake.value,
          ripple: widget.ripple,
          elapsed: _elapsed,
          repaint: Listenable.merge(<Listenable>[awake, _elapsed]),
        ),
      ),
    );
    final label = widget.semanticsLabel;
    if (label != null) {
      picture = Semantics(label: label, image: true, child: picture);
    } else {
      picture = ExcludeSemantics(child: picture);
    }
    return AspectRatio(
      aspectRatio: HorizonRingsPainter.viewBox.aspectRatio,
      child: picture,
    );
  }
}
