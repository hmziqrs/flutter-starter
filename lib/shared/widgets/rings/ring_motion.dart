import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

import 'package:starter/shared/widgets/rings/brand_seed.dart';

/// How the accent ring moves: still, one full turn, breathing (its arc grows
/// and shrinks), or its dot going round.
enum OrangeMotionKind { still, turn, breathe, orbit }

/// How the faint rings move: still, a light ripple passing through them, a
/// few of them stepping round one at a time, or one of them turning.
enum GrayMotionKind { still, ripple, dial, turn }

/// The accent ring's motion and its optional overrides.
///
/// Defaults come from [ringMotionDefaults]: turn 120s, breathe 8s (+8% arc),
/// orbit 40s. `reverse` runs turn and orbit anticlockwise.
@immutable
final class OrangeMotion {
  const OrangeMotion(this.kind, {this.seconds, this.reverse = false, this.grow});

  final OrangeMotionKind kind;

  /// Seconds for one full turn, one lap of the dot, or one grow-and-shrink.
  final double? seconds;

  /// Anticlockwise instead of clockwise (turn, orbit).
  final bool reverse;

  /// Breathe only: how much longer the arc gets, as a share of the whole
  /// ring (0.08 = 8%).
  final double? grow;

  @override
  bool operator ==(Object other) =>
      other is OrangeMotion &&
      kind == other.kind &&
      seconds == other.seconds &&
      reverse == other.reverse &&
      grow == other.grow;

  @override
  int get hashCode => Object.hash(kind, seconds, reverse, grow);
}

/// The faint rings' motion and its optional overrides.
///
/// Defaults come from [ringMotionDefaults]: ripple every 10s crossing in
/// 1.5s at strength 0.5, dial 4 rings stepping 24° every 5s, turn 170s
/// anticlockwise.
@immutable
final class GrayMotion {
  const GrayMotion(
    this.kind, {
    this.every,
    this.cross,
    this.glow,
    this.strength,
    this.inward = false,
    this.rings,
    this.step,
    this.seconds,
    this.reverse = true,
  });

  final GrayMotionKind kind;

  /// Ripple: seconds from one wave to the next.
  final double? every;

  /// Ripple: seconds for the wave to cross from the first ring to the last.
  final double? cross;

  /// Ripple: seconds each ring stays lit, up and down.
  final double? glow;

  /// Ripple: how bright a lit ring gets, as a share of the text color.
  final double? strength;

  /// Ripple: from the outside in.
  final bool inward;

  /// Dial: how many rings take turns.
  final int? rings;

  /// Dial: how far each one turns, in degrees.
  final double? step;

  /// Dial: seconds between one ring's step and the next; turn: one full turn.
  final double? seconds;

  /// Turn: anticlockwise instead of clockwise. Defaults to anticlockwise,
  /// the web's `motionDefaults.gray.turn`; dial ignores this.
  final bool reverse;

  @override
  bool operator ==(Object other) =>
      other is GrayMotion &&
      kind == other.kind &&
      every == other.every &&
      cross == other.cross &&
      glow == other.glow &&
      strength == other.strength &&
      inward == other.inward &&
      rings == other.rings &&
      step == other.step &&
      seconds == other.seconds &&
      reverse == other.reverse;

  @override
  int get hashCode =>
      Object.hash(kind, every, cross, glow, strength, inward, rings, step, seconds, reverse);
}

/// A hero picture's motion: the accent ring and the faint rings, combined.
///
/// Port of `RingMotion` in rings.ts. Still by default; only rings with a
/// move animate, and reduced motion always gets the still picture.
@immutable
final class RingMotion {
  const RingMotion({this.orange, this.gray});

  /// Every preset from rings.ts's `ringPresets`.
  static const Map<String, RingMotion> presets = <String, RingMotion>{
    'still': still,
    'ripple-turn': rippleTurn,
    'turn': turn,
    'breathe': breathe,
    'orbit': orbit,
    'pair': pair,
    'dial': dial,
    'ripple': ripple,
  };

  static const RingMotion still = RingMotion();

  static const RingMotion rippleTurn = RingMotion(
    orange: OrangeMotion(OrangeMotionKind.turn),
    gray: GrayMotion(GrayMotionKind.ripple),
  );

  static const RingMotion turn = RingMotion(orange: OrangeMotion(OrangeMotionKind.turn));

  static const RingMotion breathe = RingMotion(orange: OrangeMotion(OrangeMotionKind.breathe));

  static const RingMotion orbit = RingMotion(
    orange: OrangeMotion(OrangeMotionKind.orbit),
  );

  static const RingMotion pair = RingMotion(
    orange: OrangeMotion(OrangeMotionKind.turn),
    gray: GrayMotion(GrayMotionKind.turn),
  );

  static const RingMotion dial = RingMotion(gray: GrayMotion(GrayMotionKind.dial));

  static const RingMotion ripple = RingMotion(gray: GrayMotion(GrayMotionKind.ripple));

  final OrangeMotion? orange;

  final GrayMotion? gray;

  /// Whether any part of this motion actually moves.
  bool get moves =>
      (orange != null && orange!.kind != OrangeMotionKind.still) ||
      (gray != null && gray!.kind != GrayMotionKind.still);

  @override
  bool operator ==(Object other) =>
      other is RingMotion && orange == other.orange && gray == other.gray;

  @override
  int get hashCode => Object.hash(orange, gray);
}

/// The settings each motion kind starts from (`motionDefaults` in rings.ts).
const ringMotionDefaults = <String, double>{
  'orange.turn.seconds': 120,
  'orange.breathe.seconds': 8,
  'orange.breathe.grow': 0.08,
  'orange.orbit.seconds': 40,
  'gray.ripple.every': 10,
  'gray.ripple.cross': 1.5,
  'gray.ripple.glow': 1.6,
  'gray.ripple.strength': 0.5,
  'gray.dial.rings': 4,
  'gray.dial.step': 24,
  'gray.dial.seconds': 5,
  'gray.turn.seconds': 170,
};

/// One moving part of one ring, evaluated at a moment in time.
///
/// The painters apply these; [computeRingMoves] decides which rings move.
sealed class RingMove {
  const RingMove();
}

/// The ring, or its dot, going round: [degrees] over [seconds], linear and
/// infinite, [delay] seconds in.
final class RingTurnMove extends RingMove {
  const RingTurnMove({required this.seconds, required this.degrees, this.delay = 0});

  final double seconds;

  /// 360 clockwise, -360 anticlockwise.
  final double degrees;

  final double delay;
}

/// The accent arc breathing between two drawn lengths, its dot riding the
/// end by [dotShiftDegrees]. ease-in-out, alternating, over [seconds].
final class RingBreatheMove extends RingMove {
  const RingBreatheMove({
    required this.seconds,
    required this.drawnFrom,
    required this.drawnTo,
    required this.dotShiftDegrees,
  });

  final double seconds;

  final double drawnFrom;

  final double drawnTo;

  final double dotShiftDegrees;
}

/// A faint ring lighting up and back: an opacity wave, no movement.
///
/// Keyframes: line color at 0, lit at [peakPoint], line again at [endPoint],
/// line through the rest of the [seconds] cycle, ease-in-out between points,
/// [delay] seconds in.
final class RingRippleMove extends RingMove {
  const RingRippleMove({
    required this.seconds,
    required this.delay,
    required this.strength,
    required this.peakPoint,
    required this.endPoint,
  });

  final double seconds;

  final double delay;

  /// How bright a lit ring gets, as a share of the text color (0..1).
  final double strength;

  /// Cycle position where the wave peaks (0..1).
  final double peakPoint;

  /// Cycle position where the wave has passed (0..1).
  final double endPoint;
}

/// One faint ring stepping [stepDegrees] in its slot, resting, and stepping
/// back: keyframes at 0, [movingPoint], [landPoint] - [movingPoint],
/// [landPoint] and 1 over the [seconds] cycle, ease-in-out, [delay] in.
final class RingDialMove extends RingMove {
  const RingDialMove({
    required this.seconds,
    required this.delay,
    required this.stepDegrees,
    required this.movingPoint,
    required this.landPoint,
  });

  final double seconds;

  final double delay;

  final double stepDegrees;

  final double movingPoint;

  final double landPoint;
}

/// Per ring: which parts move, if any.
///
/// [ring] moves the whole ring (its circle and dot together); [circle] only
/// the stroked circle; [dot] only the dot.
final class RingMoves {
  const RingMoves({this.ring, this.circle, this.dot});

  final RingMove? ring;

  final RingMove? circle;

  final RingMove? dot;
}

/// Decides which rings move and how.
///
/// Port of `ringMoves()` in rings.ts, including its own random stream
/// (`rng(hash(seed) + 41)`): dial picks the same rings and steps here as on
/// the web, and the picture itself stays exactly as drawn.
List<RingMoves> computeRingMoves({
  required RingMotion motion,
  required List<RingArc> arcs,
  required String seed,
}) {
  final moves = List<RingMoves>.filled(arcs.length, const RingMoves());
  final accent = arcs.indexWhere((arc) => arc.accent);
  final random = SeededRandom(hashName(seed) + 41);
  final faint = <int>[
    for (var i = 0; i < arcs.length; i += 1)
      if (i != accent) i,
  ];

  final orange = motion.orange;
  if (orange != null && orange.kind != OrangeMotionKind.still) {
    switch (orange.kind) {
      case OrangeMotionKind.turn:
        moves[accent] = RingMoves(
          ring: RingTurnMove(
            seconds: orange.seconds ?? ringMotionDefaults['orange.turn.seconds']!,
            degrees: orange.reverse ? -360 : 360,
          ),
        );
      case OrangeMotionKind.orbit:
        moves[accent] = RingMoves(
          dot: RingTurnMove(
            seconds: orange.seconds ?? ringMotionDefaults['orange.orbit.seconds']!,
            degrees: orange.reverse ? -360 : 360,
          ),
        );
      case OrangeMotionKind.breathe:
        final arc = arcs[accent];
        final circumference = arc.circumference;
        final drawn = arc.drawn;
        final longer = math.min(
          circumference * 0.98,
          drawn + circumference * (orange.grow ?? ringMotionDefaults['orange.breathe.grow']!),
        );
        moves[accent] = RingMoves(
          circle: RingBreatheMove(
            seconds: orange.seconds ?? ringMotionDefaults['orange.breathe.seconds']!,
            drawnFrom: drawn,
            drawnTo: longer,
            // The dot turns by the same share of the ring as the arc grows.
            dotShiftDegrees: (longer - drawn) / circumference * 360,
          ),
        );
      case OrangeMotionKind.still:
        break;
    }
  }

  final gray = motion.gray;
  if (gray != null && gray.kind != GrayMotionKind.still) {
    switch (gray.kind) {
      case GrayMotionKind.ripple:
        final every = math.max(gray.every ?? ringMotionDefaults['gray.ripple.every']!, 0.5);
        final glow = math.min(
          gray.glow ?? ringMotionDefaults['gray.ripple.glow']!,
          every * 0.9,
        );
        final order = gray.inward ? faint.reversed.toList() : faint;
        final gap = order.length > 1
            ? (gray.cross ?? ringMotionDefaults['gray.ripple.cross']!) / (order.length - 1)
            : 0.0;
        for (final (n, i) in order.indexed) {
          moves[i] = RingMoves(
            circle: RingRippleMove(
              seconds: every,
              delay: n * gap,
              strength: gray.strength ?? ringMotionDefaults['gray.ripple.strength']!,
              peakPoint: glow / 2 / every,
              endPoint: glow / every,
            ),
          );
        }
      case GrayMotionKind.dial:
        final count = math.max(
          1,
          math.min(faint.length, (gray.rings ?? ringMotionDefaults['gray.dial.rings']!).round()),
        );
        final seconds = gray.seconds ?? ringMotionDefaults['gray.dial.seconds']!;
        final cycle = count * seconds * 2;
        final moving = math.min(2, seconds * 0.6) / cycle;
        // Where a ring's return settles on 0, as a share of the cycle: just
        // past half, except the last ring's — the wrap catches it one delay
        // earlier, so the loop never freezes on its first frame.
        final back = 0.5 + moving;
        final wrap = 1 - (count - 1) * seconds / cycle;
        // The same few rings, inside to out, as the web's stable sort by
        // draw: ties fall back to ring order.
        final picked = <(int, double)>[for (final i in faint) (i, random.next())]
          ..sort((x, y) {
            if (x.$2 != y.$2) {
              return x.$2 < y.$2 ? -1 : 1;
            }
            return x.$1.compareTo(y.$1);
          });
        final chosen = picked.take(count).map((entry) => entry.$1).toList()..sort();
        for (final (n, i) in chosen.indexed) {
          final step =
              (gray.step ?? ringMotionDefaults['gray.dial.step']!) *
              (0.75 + random.next() * 0.5) *
              (random.next() < 0.5 ? -1 : 1);
          moves[i] = RingMoves(
            ring: RingDialMove(
              seconds: cycle,
              delay: n * seconds,
              stepDegrees: step,
              movingPoint: moving,
              landPoint: n == count - 1 ? wrap : back,
            ),
          );
        }
      case GrayMotionKind.turn:
        final other = math.min(
          arcs.length - 2,
          accent + 2 + random.nextIndex(3),
        );
        moves[other] = RingMoves(
          ring: RingTurnMove(
            seconds: gray.seconds ?? ringMotionDefaults['gray.turn.seconds']!,
            // Defaults to anticlockwise, unlike the accent ring's turn.
            degrees: gray.reverse ? -360 : 360,
          ),
        );
      case GrayMotionKind.still:
        break;
    }
  }

  return moves;
}

/// Normalized loop position (0..1) of a move that repeats every [seconds],
/// [delay] in, holding at 0 until its delay has passed.
double ringPhase(double elapsedSeconds, double seconds, double delay) {
  if (seconds <= 0 || elapsedSeconds <= delay) {
    return 0;
  }
  final position = ((elapsedSeconds - delay) / seconds) % 1;
  return position < 0 ? position + 1 : position;
}

/// Evaluates a move's keyframes at [elapsedSeconds].
///
/// [points] are (cycle position, value) pairs with the first at 0 and the
/// last at 1; [curve] eases each segment, the way CSS applies its timing
/// function between keyframes.
double ringKeyframe(
  double elapsedSeconds,
  double seconds,
  double delay,
  List<(double, double)> points,
  Curve curve,
) {
  final position = ringPhase(elapsedSeconds, seconds, delay);
  for (var i = 0; i < points.length - 1; i += 1) {
    final (x0, y0) = points[i];
    final (x1, y1) = points[i + 1];
    if (position <= x1) {
      final span = x1 - x0;
      if (span <= 0) {
        return y1;
      }
      return lerpDouble(y0, y1, curve.transform((position - x0) / span))!;
    }
  }
  return points.last.$2;
}

/// The eased position (0..1) of a breathe move that grows over [seconds] and
/// shrinks back, alternating forever.
double ringAlternate(double elapsedSeconds, double seconds) {
  if (seconds <= 0) {
    return 0;
  }
  final cycle = (elapsedSeconds / seconds) % 2;
  final up = cycle <= 1 ? cycle : 2 - cycle;
  return Curves.easeInOut.transform(up.clamp(0.0, 1.0));
}
