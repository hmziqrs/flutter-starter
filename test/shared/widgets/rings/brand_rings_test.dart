import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/shared/widgets/rings/brand_rings.dart';
import 'package:starter/shared/widgets/rings/brand_seed.dart';
import 'package:starter/shared/widgets/rings/ring_motion.dart';

List<RingArc> _hero(String seed) {
  final random = SeededRandom(hashName(seed) + 7);
  final accent = 3 + random.nextIndex(3);
  return seedArcs(
    random,
    cx: 440,
    cy: 225,
    radii: <double>[for (var i = 0; i < 11; i += 1) 34.0 + 34 * i],
    accent: accent,
    accentGap: 0.52,
    gapRange: (0.06, 0.3),
  );
}

String _moveSignature(RingMove move) => switch (move) {
  RingTurnMove(:final seconds, :final degrees, :final delay) => 'turn $seconds $degrees $delay',
  RingBreatheMove(
    :final seconds,
    :final drawnFrom,
    :final drawnTo,
    :final dotShiftDegrees,
  ) =>
    'breathe $seconds $drawnFrom $drawnTo $dotShiftDegrees',
  RingRippleMove(:final seconds, :final delay, :final strength) =>
    'ripple $seconds $delay $strength',
  RingDialMove(:final seconds, :final delay, :final stepDegrees) =>
    'dial $seconds $delay $stepDegrees',
};

void main() {
  group('computeRingMoves (port of rings.ts ringMoves)', () {
    final arcs = _hero('flutter'); // Accent ring 5.

    test('still moves nothing', () {
      final moves = computeRingMoves(motion: RingMotion.still, arcs: arcs, seed: 'flutter');
      expect(
        moves.every((move) => move.ring == null && move.circle == null && move.dot == null),
        isTrue,
      );
    });

    test('turn moves only the accent ring, 360 degrees over 120s', () {
      // bun: ringMoves(ringPresets.turn, arcs, "flutter") ->
      //   ring 5: {ring: {kind: turn, --duration: 120.00s, --turn: 360deg}}
      final moves = computeRingMoves(motion: RingMotion.turn, arcs: arcs, seed: 'flutter');
      final turn = moves[5].ring;
      expect(turn, isA<RingTurnMove>());
      expect(_moveSignature(turn!), 'turn 120.0 360.0 0.0');
      expect(
        moves.where((move) => move.ring != null),
        hasLength(1),
        reason: 'only one ring ever turns',
      );
    });

    test('orbit moves only the accent dot, 40s', () {
      // bun: ring 5: {dot: {kind: turn, --duration: 40.00s, --turn: 360deg}}
      final moves = computeRingMoves(motion: RingMotion.orbit, arcs: arcs, seed: 'flutter');
      final orbit = moves[5].dot;
      expect(orbit, isA<RingTurnMove>());
      expect(_moveSignature(orbit!), 'turn 40.0 360.0 0.0');
      expect(moves[5].ring, isNull);
    });

    test('breathe grows the accent arc and rides its dot', () {
      // bun: ring 5: {circle: {kind: breathe, --dash-from: 615.25 666.52,
      //   --dash-to: 717.79 563.98}, dot: {kind: breathe-dot, --shift: 28.80deg}}
      final moves = computeRingMoves(motion: RingMotion.breathe, arcs: arcs, seed: 'flutter');
      final breathe = moves[5].circle;
      expect(breathe, isA<RingBreatheMove>());
      final (from, to, shift) = switch (breathe!) {
        RingBreatheMove(
          :final drawnFrom,
          :final drawnTo,
          :final dotShiftDegrees,
        ) =>
          (drawnFrom, drawnTo, dotShiftDegrees),
        _ => (0.0, 0.0, 0.0),
      };
      expect(from, 615.25);
      // The web rounds this to "717.79" only for its dash string; the
      // painter draws from the unrounded length, like rings.ts does.
      expect(to, closeTo(717.79, 0.01));
      expect(shift, closeTo(28.80, 0.01));
      expect(moves[5].dot, isNull);
    });

    test('ripple waves through the faint rings, never the accent', () {
      // bun: rings 0-4 and 6-10, --delay 0.00s .. 1.50s in 0.1667s steps.
      final moves = computeRingMoves(motion: RingMotion.ripple, arcs: arcs, seed: 'flutter');
      final rippled = <int>[
        for (var i = 0; i < arcs.length; i += 1)
          if (moves[i].circle != null) i,
      ];
      expect(rippled, const <int>[0, 1, 2, 3, 4, 6, 7, 8, 9, 10]);
      final first = moves[0].circle! as RingRippleMove;
      expect(first.seconds, 10);
      expect(first.delay, 0);
      final last = moves[10].circle! as RingRippleMove;
      expect(last.delay, closeTo(1.5, 0.001));
      expect(
        moves[5].ring,
        isNull,
        reason: 'the accent ring does not ripple',
      );
    });

    test('ripple-turn combines the accent turn with the ripple', () {
      final moves = computeRingMoves(
        motion: RingMotion.rippleTurn,
        arcs: arcs,
        seed: 'flutter',
      );
      expect(moves[5].ring, isA<RingTurnMove>());
      expect(moves[0].circle, isA<RingRippleMove>());
    });

    test('pair turns the accent clockwise and a bigger ring anticlockwise', () {
      // bun: ring 5: turn 120.00s 360deg; ring 9: turn 170.00s -360deg.
      final moves = computeRingMoves(motion: RingMotion.pair, arcs: arcs, seed: 'flutter');
      final accentTurn = moves[5].ring! as RingTurnMove;
      expect(_moveSignature(accentTurn), 'turn 120.0 360.0 0.0');
      final grayTurn = moves[9].ring! as RingTurnMove;
      expect(_moveSignature(grayTurn), 'turn 170.0 -360.0 0.0');
    });

    test('dial picks the same rings and steps as the web', () {
      // bun: rings 1, 2, 7, 9 stepping 26.7, -27.2, -29.2, -22.0 degrees,
      // --delay 0, 5, 10, 15 over a 40s cycle.
      final moves = computeRingMoves(motion: RingMotion.dial, arcs: arcs, seed: 'flutter');
      final dialled = <int>[
        for (var i = 0; i < arcs.length; i += 1)
          if (moves[i].ring != null) i,
      ];
      expect(dialled, const <int>[1, 2, 7, 9]);
      final steps = <double>[
        for (final i in dialled) (moves[i].ring! as RingDialMove).stepDegrees,
      ];
      expect(steps[0], closeTo(26.7, 0.05));
      expect(steps[1], closeTo(-27.2, 0.05));
      expect(steps[2], closeTo(-29.2, 0.05));
      expect(steps[3], closeTo(-22.0, 0.05));
      final delays = <double>[
        for (final i in dialled) (moves[i].ring! as RingDialMove).delay,
      ];
      expect(delays, const <double>[0, 5, 10, 15]);
      // count 4, seconds 5: cycle 40, moving min(2, 3)/40, back 0.5 + moving,
      // wrap 1 - 15/40.
      final first = moves[1].ring! as RingDialMove;
      expect(first.seconds, 40);
      expect(first.movingPoint, closeTo(2 / 40, 0.0001));
      expect(first.landPoint, closeTo(0.5 + 2 / 40, 0.0001));
      final last = moves[9].ring! as RingDialMove;
      expect(last.landPoint, closeTo(1 - 15 / 40, 0.0001));
    });

    test('moves are deterministic per seed and leave the picture as drawn', () {
      final again = computeRingMoves(motion: RingMotion.dial, arcs: arcs, seed: 'flutter');
      final moves = computeRingMoves(motion: RingMotion.dial, arcs: arcs, seed: 'flutter');
      expect(
        [for (final move in moves) move.ring?.runtimeType],
        [for (final move in again) move.ring?.runtimeType],
      );
      // The arcs themselves are untouched by motion.
      expect(_hero('flutter').map(_arcSignature), arcs.map(_arcSignature));
    });
  });

  group('heroRings recipe', () {
    test('the same name gives the same picture, motion does not change it', () {
      final still = heroRings('starter');
      final moving = heroRings('starter', motion: RingMotion.rippleTurn);
      expect(
        still.arcs.map(_arcSignature),
        moving.arcs.map(_arcSignature),
      );
      expect(still.arcs.first.accent, isFalse);
    });

    test('the accent index rule holds across names', () {
      for (final name in const <String>['flutter', 'starter', 'hmziq', 'a', 'zz']) {
        final random = SeededRandom(hashName(name) + 7);
        expect(3 + random.nextIndex(3), inInclusiveRange(3, 5), reason: name);
      }
    });
  });

  group('ring motion timing helpers', () {
    test('ringPhase holds at 0 before the delay, then loops', () {
      expect(ringPhase(1, 10, 2), 0);
      expect(ringPhase(2, 10, 2), 0);
      expect(ringPhase(7, 10, 2), closeTo(0.5, 0.0001));
      expect(ringPhase(12, 10, 2), closeTo(0, 0.0001));
      expect(ringPhase(-1, 10, 0), 0, reason: 'no negative time');
    });

    test('ringKeyframe eases each segment', () {
      // A triangle: 0 at 0, 1 at 0.5, 0 at 1.
      const points = <(double, double)>[(0, 0), (0.5, 1), (1, 0)];
      expect(ringKeyframe(0, 10, 0, points, Curves.linear), 0);
      expect(ringKeyframe(2.5, 10, 0, points, Curves.linear), 0.5);
      expect(ringKeyframe(5, 10, 0, points, Curves.linear), 1);
      expect(ringKeyframe(10, 10, 0, points, Curves.linear), 0);
      // easeInOut mid-segment is slower than linear: 0.5 -> easeInOut(0.5)=0.5,
      // quarter point 0.25 -> easeInOut(0.25) < 0.25.
      expect(
        ringKeyframe(1.25, 10, 0, points, Curves.easeInOut),
        lessThan(0.25),
      );
      expect(ringKeyframe(1, 10, 2, points, Curves.linear), 0, reason: 'delay');
    });

    test('ringAlternate grows and shrinks', () {
      expect(ringAlternate(0, 8), 0);
      expect(ringAlternate(8, 8), closeTo(1, 0.0001), reason: 'peak at one cycle');
      expect(ringAlternate(16, 8), closeTo(0, 0.0001), reason: 'back at two cycles');
      expect(ringAlternate(24, 8), closeTo(1, 0.0001), reason: 'alternating');
      final mid = ringAlternate(4, 8);
      expect(mid, closeTo(0.5, 0.0001));
      expect(ringAlternate(12, 8), closeTo(0.5, 0.0001), reason: 'symmetric');
    });
  });
}

String _arcSignature(RingArc arc) =>
    '${arc.radius}|${arc.drawn}|${arc.gap}|${arc.rotateDegrees}|${arc.accent}|${arc.end}';
