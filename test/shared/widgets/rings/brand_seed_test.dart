import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:starter/shared/widgets/rings/brand_seed.dart';

/// Reference values captured by running the originals —
/// `packages/brand-core/src/motion/rings.ts` and `ring-shapes.ts` — under
/// bun. The port must give the same numbers for the same name, so the same
/// name draws the same picture on the web and here.
void main() {
  group('hashName (FNV-1a)', () {
    test('matches the TypeScript hash bit-for-bit', () {
      expect(hashName('flutter'), 391927001);
      expect(hashName('starter'), 2455336948);
      expect(hashName('hmziq'), 3733951930);
      expect(hashName('oxide'), 2866236174);
    });

    test('is stable and wraps to 32 bits', () {
      expect(hashName('flutter'), hashName('flutter'));
      expect(hashName('flutter'), isNot(hashName('starter')));
      expect(hashName(''), 2166136261); // FNV-1a offset basis.
      expect(hashName('Ⅷ'), lessThanOrEqualTo(0xFFFFFFFF));
    });
  });

  group('SeededRandom (mulberry32)', () {
    test('matches the TypeScript sequence bit-for-bit', () {
      // bun: const r = rng(42); six draws.
      final expected = <double>[
        0.6011037519201636,
        0.44829055899754167,
        0.8524657934904099,
        0.6697340414393693,
        0.17481389874592423,
        0.5265925421845168,
      ];
      final random = SeededRandom(42);
      for (final value in expected) {
        expect(random.next(), closeTo(value, 1e-15));
      }
    });

    test('wraps seeds above 32 bits like `seed |= 0`', () {
      // hash returns 0..2^32-1; hash + 7 can reach 2^32 + 6. The original
      // coerces with | 0, keeping the low 32 bits.
      final wrapped = SeededRandom(4294967296 + 6);
      final direct = SeededRandom(6);
      expect(wrapped.next(), direct.next());
    });
  });

  group('hero rings recipe (BRAND.md s7)', () {
    const radii = <double>[34, 68, 102, 136, 170, 204, 238, 272, 306, 340, 374];

    // bun, rings.ts: rng(hash(seed) + 7), accent = 3 + floor(r() * 3),
    // arcs(random, { cx: 440, cy: 225, radii, accent, accentGap: 0.52, gap: [0.06, 0.3] })
    test('matches the TypeScript arcs bit-for-bit for "flutter"', () {
      const reference = <List<double>>[
        <double>[198.47, 15.16, 229.49],
        <double>[368.97, 58.29, 318.1],
        <double>[567.95, 72.94, 124.81],
        <double>[595.51, 259, 287.83],
        <double>[941.35, 126.79, 128.65],
        <double>[615.25, 666.52, 133.52],
        <double>[1387.39, 108.01, 91.81],
        <double>[1463.26, 245.76, 3.6],
        <double>[1552.41, 370.25, 128.44],
        <double>[1927.07, 209.21, 56.97],
        <double>[2033.15, 316.76, 2.29],
      ];
      final random = SeededRandom(hashName('flutter') + 7);
      final accent = 3 + random.nextIndex(3);
      expect(accent, 5);
      final arcs = seedArcs(
        random,
        cx: 440,
        cy: 225,
        radii: radii,
        accent: accent,
        accentGap: 0.52,
        gapRange: (0.06, 0.3),
      );
      expect(arcs, hasLength(11));
      for (var i = 0; i < arcs.length; i += 1) {
        expect(arcs[i].drawn, reference[i][0], reason: 'ring $i drawn');
        expect(arcs[i].gap, reference[i][1], reason: 'ring $i gap');
        expect(arcs[i].rotateDegrees, reference[i][2], reason: 'ring $i rotate');
        expect(arcs[i].accent, i == accent, reason: 'ring $i accent');
      }
      expect(arcs[accent].end, const Offset(560.83, 60.64));
      // Only the accent ring carries an end point.
      expect(
        arcs.where((arc) => arc.end != null),
        hasLength(1),
      );
    });

    test('matches the TypeScript arcs for "starter" and "hmziq"', () {
      for (final (name, refAccent, refEnd) in <(String, int, Offset)>[
        ('starter', 4, const Offset(547.92, 356.35)),
        ('hmziq', 4, const Offset(468.26, 392.63)),
        ('oxide', 4, const Offset(318.54, 343.94)),
      ]) {
        final random = SeededRandom(hashName(name) + 7);
        final accent = 3 + random.nextIndex(3);
        final arcs = seedArcs(
          random,
          cx: 440,
          cy: 225,
          radii: radii,
          accent: accent,
          accentGap: 0.52,
          gapRange: (0.06, 0.3),
        );
        expect(accent, refAccent, reason: name);
        expect(arcs[accent].end, refEnd, reason: name);
      }
    });

    test('the same name always gives the same arcs', () {
      List<RingArc> draw(String seed) {
        final random = SeededRandom(hashName(seed) + 7);
        final accent = 3 + random.nextIndex(3);
        return seedArcs(
          random,
          cx: 440,
          cy: 225,
          radii: radii,
          accent: accent,
          accentGap: 0.52,
          gapRange: (0.06, 0.3),
        );
      }

      expect(draw('flutter').map(_arcSignature), draw('flutter').map(_arcSignature));
    });

    test('a different name gives different arcs', () {
      List<RingArc> draw(String seed) {
        final random = SeededRandom(hashName(seed) + 7);
        final accent = 3 + random.nextIndex(3);
        return seedArcs(
          random,
          cx: 440,
          cy: 225,
          radii: radii,
          accent: accent,
          accentGap: 0.52,
          gapRange: (0.06, 0.3),
        );
      }

      final flutter = draw('flutter').map(_arcSignature).toList();
      final starter = draw('starter').map(_arcSignature).toList();
      expect(flutter, isNot(orderedEquals(starter)));
    });

    test('accent ring index stays within 3..5 and gaps stay in 6-36%', () {
      for (final name in const <String>['a', 'bb', 'ccc', 'flutter', 'starter', 'hmziq']) {
        final random = SeededRandom(hashName(name) + 7);
        final accent = 3 + random.nextIndex(3);
        expect(accent, inInclusiveRange(3, 5), reason: name);
        final arcs = seedArcs(
          random,
          cx: 440,
          cy: 225,
          radii: radii,
          accent: accent,
          accentGap: 0.52,
          gapRange: (0.06, 0.3),
        );
        for (final (i, arc) in arcs.indexed) {
          final share = arc.gap / arc.circumference;
          if (i == accent) {
            expect(share, closeTo(0.52, 0.0001), reason: '$name ring $i');
          } else {
            expect(share, inInclusiveRange(0.06, 0.36), reason: '$name ring $i');
          }
        }
      }
    });
  });

  group('corner rings recipe (BRAND.md s7)', () {
    const radii = <double>[11, 22, 33, 44, 55, 66, 77, 88, 99];

    // bun, rings.ts + kits' corner-rings: rng(hash(seed) + 23),
    // accent = 3 + hash(seed) % 3, arcs(random, { cx: 100, cy: 0, radii,
    // accent, accentGap: 0.5, gap: [0.1, 0.3] })
    test('matches the TypeScript arcs bit-for-bit for "flutter"', () {
      const reference = <List<double>>[
        <double>[57.14, 11.97, 192.54],
        <double>[88.25, 49.98, 212.96],
        <double>[186.01, 21.33, 119.35],
        <double>[188.90, 87.56, 141.87],
        <double>[212.05, 133.53, 177.63],
        <double>[207.35, 207.35, 184.54],
        <double>[389.96, 93.84, 252.82],
        <double>[371.85, 181.07, 34.99],
        <double>[461.86, 160.18, 207.13],
      ];
      final hash = hashName('flutter');
      final accent = 3 + hash % 3;
      expect(accent, 5);
      final arcs = seedArcs(
        SeededRandom(hash + 23),
        cx: 100,
        cy: 0,
        radii: radii,
        accent: accent,
        accentGap: 0.5,
        gapRange: (0.1, 0.3),
      );
      for (var i = 0; i < arcs.length; i += 1) {
        expect(arcs[i].drawn, reference[i][0], reason: 'ring $i drawn');
        expect(arcs[i].gap, reference[i][1], reason: 'ring $i gap');
        expect(arcs[i].rotateDegrees, reference[i][2], reason: 'ring $i rotate');
      }
      expect(arcs[accent].end, const Offset(165.79, 5.23));
    });

    test('accent ring index follows 3 + hash(name) % 3', () {
      for (final (name, refAccent) in const <(String, int)>[
        ('starter', 4),
        ('hmziq', 3 + 3733951930 % 3),
        ('oxide', 3 + 2866236174 % 3),
      ]) {
        expect(3 + hashName(name) % 3, refAccent, reason: name);
        expect(3 + hashName(name) % 3, inInclusiveRange(3, 5), reason: name);
      }
    });

    test('quiet variant shifts the seed and drops the dot', () {
      final hash = hashName('flutter');
      final arcs = seedArcs(
        SeededRandom(hash + 29),
        cx: 100,
        cy: 0,
        radii: <double>[for (var i = 0; i < 8; i++) 12.0 + 12 * i],
        accent: 2 + hash % 3,
        accentGap: 0.5,
        gapRange: (0.1, 0.3),
      );
      expect(arcs, hasLength(8));
      expect(arcs[2 + hash % 3].accent, isTrue);
    });
  });

  group('band arcs recipe (BRAND.md s7)', () {
    test('is deterministic: ring 3 accents, turns step 150 + 23i degrees', () {
      // bun, kits' band-arcs.svelte.
      const reference = <(double, double, double, bool)>[
        (301.59, 75.4, 150, false),
        (522.76, 130.69, 173, false),
        (743.93, 185.98, 196, false),
        (482.55, 723.82, 219, true),
        (1186.27, 296.57, 242, false),
        (1407.43, 351.86, 265, false),
        (1628.6, 407.15, 288, false),
        (1849.77, 462.44, 311, false),
      ];
      final arcs = <RingArc>[
        for (var i = 0; i < 8; i += 1)
          () {
            final radius = 60.0 + 44 * i;
            final circumference = 2 * math.pi * radius;
            final gap = circumference * (i == 3 ? 0.6 : 0.2);
            return RingArc(
              radius: radius,
              drawn: round2(circumference - gap),
              gap: round2(gap),
              rotateDegrees: (150 + 23 * i).toDouble(),
              accent: i == 3,
            );
          }(),
      ];
      for (var i = 0; i < arcs.length; i += 1) {
        final arc = arcs[i];
        expect(arc.drawn, reference[i].$1, reason: 'ring $i drawn');
        expect(arc.gap, reference[i].$2, reason: 'ring $i gap');
        expect(arc.rotateDegrees, reference[i].$3, reason: 'ring $i rotate');
        expect(arc.accent, reference[i].$4, reason: 'ring $i accent');
        expect(arc.end, isNull, reason: 'ring $i has no dot');
      }
    });
  });

  group('horizon arcs recipe (ring-shapes.ts)', () {
    // bun, ring-shapes.ts: horizonArcs(seed, { cx: 300, cy: 262,
    // radii: 46 + 24i (10), accent: 2 })
    List<HorizonArc> draw(String seed) => horizonArcs(
      seed,
      cx: 300,
      cy: 262,
      radii: <double>[for (var i = 0; i < 10; i++) 46.0 + 24 * i],
      accent: 2,
    );

    double pointX(double radius, double angle) => 300 + radius * math.cos(angle);
    double pointY(double radius, double angle) => 262 + radius * math.sin(angle);

    test('matches the TypeScript sun path bit-for-bit for "flutter"', () {
      final arcs = draw('flutter');
      final sun = arcs[2];
      expect(sun.accent, isTrue);
      expect(sun.segments, hasLength(1));
      final (start, sweep) = sun.segments.single;
      expect(round2(pointX(94, start)), 206); // M206 262
      expect(round2(pointY(94, start)), 262);
      expect(round2(pointX(94, start + sweep)), 289.48); // ...289.48 168.59
      expect(round2(pointY(94, start + sweep)), 168.59);
      expect(sun.end, const Offset(289.48, 168.59));
    });

    test('matches the TypeScript segment counts for both seeds', () {
      expect(draw('flutter').map((arc) => arc.segments.length), const <int>[
        3, 3, 1, 3, 2, 4, 3, 3, 6, 3, // flutter
      ]);
      expect(draw('starter').map((arc) => arc.segments.length), const <int>[
        4, 3, 1, 3, 3, 4, 4, 3, 4, 3, // starter
      ]);
      expect(draw('starter')[2].end, const Offset(299.94, 168));
      expect(
        draw('starter').map((arc) => arc.accent).toList(),
        predicate<List<bool>>((accents) => accents.where((accent) => accent).length == 1),
      );
    });

    test('the same seed gives the same arcs; a different seed does not', () {
      List<String> signature(String seed) => draw(seed).map(_horizonSignature).toList();
      expect(signature('flutter'), signature('flutter'));
      expect(signature('flutter'), isNot(orderedEquals(signature('starter'))));
    });

    test('stars draw from their own stream', () {
      final stars = horizonStars('flutter');
      expect(stars, hasLength(14));
      for (final (position, radius) in stars) {
        expect(position.dx, inInclusiveRange(30, 570));
        expect(position.dy, inInclusiveRange(18, 168));
        expect(radius, inInclusiveRange(0.8, 2.1));
      }
      expect(
        horizonStars('flutter').map((star) => star.$1),
        horizonStars('flutter').map((star) => star.$1),
      );
      expect(
        horizonStars('flutter').map((star) => star.$1),
        isNot(horizonStars('starter').map((star) => star.$1)),
      );
    });
  });
}

String _arcSignature(RingArc arc) =>
    '${arc.radius}|${arc.drawn}|${arc.gap}|${arc.rotateDegrees}|${arc.accent}|${arc.end}';

String _horizonSignature(HorizonArc arc) =>
    '${arc.radius}|${arc.segments.map((segment) => '${segment.$1},${segment.$2}').join(';')}|${arc.end}';
