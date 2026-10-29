import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/brand_tokens.dart';
import 'package:starter/shared/widgets/rings/brand_seed.dart';
import 'package:starter/shared/widgets/rings/ring_motion.dart';

export 'ring_motion.dart' show RingMotion;

/// The hero rings recipe (BRAND.md s7): 11 rings around (440, 225) in a
/// 520x440 picture, radius `34 + 34 * i`, drawn from [seed] with
/// `hash(seed) + 7`. The accent is ring `3 + floor(r() * 3)`: a 52% gap and
/// a dot of radius 7 where it ends. The rest gap 6-36% and every ring is
/// turned `r() * 360` degrees.
///
/// Returns the arcs and, for [motion], which parts of which rings move —
/// the same mix of rings the web's `ringMoves` picks.
({List<RingArc> arcs, List<RingMoves> moves}) heroRings(
  String seed, {
  RingMotion motion = RingMotion.still,
}) {
  final random = SeededRandom(hashName(seed) + 7);
  final accent = 3 + random.nextIndex(3);
  final arcs = seedArcs(
    random,
    cx: 440,
    cy: 225,
    radii: <double>[for (var i = 0; i < 11; i += 1) 34.0 + 34 * i],
    accent: accent,
    accentGap: 0.52,
    gapRange: (0.06, 0.3),
  );
  return (
    arcs: arcs,
    moves: computeRingMoves(motion: motion, arcs: arcs, seed: seed),
  );
}

/// Paints a ring picture: faint rings in [lineColor], the accent ring in
/// [accentColor], each with one gap, round caps, and the accent's dot at its
/// arc's end.
///
/// Port of the kits' `ring-circles` component. All measures are in viewBox
/// units and scale together with the box ([viewBox] maps onto the canvas
/// bounds, kept ratio-tight like an SVG `viewBox`), and the picture clips to
/// its box the way SVG clips to its viewBox.
class RingPicturePainter extends CustomPainter {
  RingPicturePainter({
    required this.arcs,
    required this.center,
    required this.viewBox,
    required this.lineWidth,
    required this.accentWidth,
    required this.dotRadius,
    required this.lineColor,
    required this.accentColor,
    this.foregroundColor,
    this.moves = const <RingMoves>[],
    ValueListenable<double>? elapsed,
    super.repaint,
  }) : _elapsed = elapsed ?? const _StaticElapsed(0);

  /// The rings to draw, in viewBox units.
  final List<RingArc> arcs;

  /// The rings' center, in viewBox units.
  final Offset center;

  /// The coordinate space the picture is drawn in, mapped onto the canvas.
  final Size viewBox;

  /// Stroke width of the faint rings.
  final double lineWidth;

  /// Stroke width of the accent ring.
  final double accentWidth;

  /// Radius of the accent ring's end dot.
  final double dotRadius;

  /// The hairline color: the text color at 22%.
  final Color lineColor;

  /// The accent color: primary, or a caller-passed role color.
  final Color accentColor;

  /// The text color the ripple waves toward; required when any ring ripples.
  final Color? foregroundColor;

  /// Which parts of which rings move; rings without a move stay as drawn.
  final List<RingMoves> moves;

  final ValueListenable<double> _elapsed;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / viewBox.width;
    final elapsed = _elapsed.value;
    canvas
      ..save()
      ..clipRect(Offset.zero & size)
      ..scale(scale);
    for (final (index, arc) in arcs.indexed) {
      final move = index < moves.length ? moves[index] : const RingMoves();
      _paintRing(canvas, arc, move, elapsed);
    }
    canvas.restore();
  }

  void _paintRing(Canvas canvas, RingArc arc, RingMoves move, double elapsed) {
    final rect = Rect.fromCircle(center: center, radius: arc.radius);
    final isAccent = arc.accent;
    final strokeWidth = isAccent ? accentWidth : lineWidth;
    var circleColor = isAccent ? accentColor : lineColor;
    var drawn = arc.drawn;
    var groupRotationDegrees = 0.0;
    var dotRotationDegrees = 0.0;

    final ringMove = move.ring;
    if (ringMove is RingTurnMove) {
      groupRotationDegrees =
          ringMove.degrees * ringPhase(elapsed, ringMove.seconds, ringMove.delay);
    } else if (ringMove is RingDialMove) {
      groupRotationDegrees =
          ringMove.stepDegrees *
          ringKeyframe(
            elapsed,
            ringMove.seconds,
            ringMove.delay,
            <(double, double)>[
              (0, 0),
              (ringMove.movingPoint, 1),
              (ringMove.landPoint - ringMove.movingPoint, 1),
              (ringMove.landPoint, 0),
              (1, 0),
            ],
            Curves.easeInOut,
          );
    }

    final circleMove = move.circle;
    if (circleMove is RingBreatheMove) {
      final eased = ringAlternate(elapsed, circleMove.seconds);
      drawn = lerpDouble(circleMove.drawnFrom, circleMove.drawnTo, eased)!;
      dotRotationDegrees += circleMove.dotShiftDegrees * eased;
    } else if (circleMove is RingRippleMove) {
      final foreground = foregroundColor;
      assert(
        foreground != null,
        'RingPicturePainter.foregroundColor is required for ripple moves',
      );
      final lit = (foreground ?? accentColor).withValues(alpha: circleMove.strength);
      final wave = ringKeyframe(
        elapsed,
        circleMove.seconds,
        circleMove.delay,
        <(double, double)>[(0, 0), (circleMove.peakPoint, 1), (circleMove.endPoint, 0), (1, 0)],
        Curves.easeInOut,
      );
      circleColor = Color.lerp(circleColor, lit, wave)!;
    }

    final dotMove = move.dot;
    if (dotMove is RingTurnMove) {
      dotRotationDegrees += dotMove.degrees * ringPhase(elapsed, dotMove.seconds, dotMove.delay);
    }

    canvas.drawArc(
      rect,
      (arc.rotateDegrees + groupRotationDegrees) * math.pi / 180,
      drawn / arc.radius,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = circleColor,
    );

    final end = arc.end;
    if (end != null) {
      // The dot rides the arc's end: its base angle plus any rotations.
      final baseAngle = arc.rotateDegrees * math.pi / 180 + arc.drawn / arc.radius;
      final angle = baseAngle + (groupRotationDegrees + dotRotationDegrees) * math.pi / 180;
      canvas.drawCircle(
        Offset(
          center.dx + arc.radius * math.cos(angle),
          center.dy + arc.radius * math.sin(angle),
        ),
        dotRadius,
        Paint()..color = accentColor,
      );
    }
  }

  @override
  bool shouldRepaint(RingPicturePainter oldDelegate) =>
      arcs != oldDelegate.arcs ||
      center != oldDelegate.center ||
      viewBox != oldDelegate.viewBox ||
      lineWidth != oldDelegate.lineWidth ||
      accentWidth != oldDelegate.accentWidth ||
      dotRadius != oldDelegate.dotRadius ||
      lineColor != oldDelegate.lineColor ||
      accentColor != oldDelegate.accentColor ||
      foregroundColor != oldDelegate.foregroundColor ||
      moves != oldDelegate.moves;
}

/// Holds a fixed elapsed time for still pictures.
final class _StaticElapsed implements ValueListenable<double> {
  const _StaticElapsed(this.value);

  @override
  final double value;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}

/// The hero picture: eleven rings coming in from the right edge, one of them
/// the accent color with a dot where it ends.
///
/// Drawn from [BrandRings.seed], so the same name always draws the same
/// rings. Still by default; give it a [RingMotion] preset for a little
/// movement — only the rings a motion marks move, [BrandRings.paused] stops
/// it where it is, reduced motion always gets the still picture, and the
/// movement stops off screen (TickerMode).
///
/// Decorative: pass [BrandRings.semanticsLabel] to describe the picture for
/// screen readers, otherwise it is excluded from semantics.
class BrandRings extends StatefulWidget {
  const BrandRings({
    required this.seed,
    this.motion = RingMotion.still,
    this.paused = false,
    this.accentColor,
    this.semanticsLabel,
    super.key,
  });

  /// The site's or project's name.
  final String seed;

  /// A little movement, from [RingMotion.presets] or your own mix.
  final RingMotion motion;

  /// Stops the movement where it is.
  final bool paused;

  /// The accent color; defaults to the theme's primary.
  final Color? accentColor;

  /// What the picture shows, for screen readers.
  final String? semanticsLabel;

  @override
  State<BrandRings> createState() => BrandRingsState();
}

/// State for [BrandRings]; [animating] is visible for tests.
class BrandRingsState extends State<BrandRings> with SingleTickerProviderStateMixin {
  static const Size _viewBox = Size(520, 440);
  static const Offset _center = Offset(440, 225);
  static const double _lineWidth = 1.25;
  static const double _accentWidth = 3;
  static const double _dotRadius = 7;

  Ticker? _ticker;

  final ValueNotifier<double> _elapsed = ValueNotifier<double>(0);

  late List<RingArc> _arcs;

  late List<RingMoves> _moves;

  bool _reducedMotion = false;

  /// Whether the movement is running; false when still, paused, or under
  /// reduced motion.
  @visibleForTesting
  bool get animating => _ticker != null;

  @override
  void initState() {
    super.initState();
    _draw();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    _syncTicker();
  }

  @override
  void didUpdateWidget(BrandRings oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seed != widget.seed || oldWidget.motion != widget.motion) {
      _draw();
    }
    _syncTicker();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _elapsed.dispose();
    super.dispose();
  }

  void _draw() {
    final picture = heroRings(widget.seed, motion: widget.motion);
    _arcs = picture.arcs;
    _moves = picture.moves;
  }

  bool get _shouldAnimate => !_reducedMotion && !widget.paused && widget.motion.moves;

  void _syncTicker() {
    if (_shouldAnimate) {
      final ticker = _ticker ??= createTicker(_onTick);
      if (!ticker.isActive) {
        unawaited(ticker.start());
      }
    } else {
      _ticker
        ?..stop()
        ..dispose();
      _ticker = null;
      if (_elapsed.value != 0) {
        _elapsed.value = 0;
      }
    }
  }

  void _onTick(Duration elapsed) {
    _elapsed.value = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    Widget picture = CustomPaint(
      painter: RingPicturePainter(
        arcs: _arcs,
        center: _center,
        viewBox: _viewBox,
        lineWidth: _lineWidth,
        accentWidth: _accentWidth,
        dotRadius: _dotRadius,
        lineColor: theme.brand.line,
        accentColor: widget.accentColor ?? theme.colors.primary,
        foregroundColor: theme.colors.foreground,
        moves: _moves,
        elapsed: _elapsed,
        repaint: _elapsed,
      ),
    );
    final label = widget.semanticsLabel;
    if (label != null) {
      picture = Semantics(label: label, image: true, child: picture);
    } else {
      // Rings are never drawn behind text and mean nothing on their own.
      picture = ExcludeSemantics(child: picture);
    }
    return AspectRatio(aspectRatio: _viewBox.aspectRatio, child: picture);
  }
}
