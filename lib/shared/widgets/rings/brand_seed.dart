import 'dart:math' as math;
import 'dart:ui';

/// Bit-for-bit Dart port of the brand's seeded ring generators
/// (`packages/brand-core/src/motion/rings.ts`): FNV-1a hashing and the
/// mulberry32 generator. The same name must always give the same picture, on
/// the web and here, so both keep the 32-bit arithmetic of the originals.
const int _offsetBasis = 2166136261;

const int _prime = 16777619;

/// Masks a signed or wider int down to its low 32 bits as an unsigned value.
///
/// JS numbers keep the low 32 bits of every bitwise step (`| 0`, `>>> 0`,
/// `Math.imul`); Dart ints are 64-bit, so every step of the port masks with
/// this to stay bit-for-bit.
const int _mask32 = 0xFFFFFFFF;

/// FNV-1a: a stable unsigned 32-bit number from a string.
///
/// Matches `hash()` in rings.ts, including its treatment of characters
/// outside the basic multilingual plane: the web code walks code points and
/// reads each one's first UTF-16 code unit, so astral characters contribute
/// their high surrogate and their low surrogate is skipped.
int hashName(String text) {
  var h = _offsetBasis;
  for (final rune in text.runes) {
    final unit = rune < 0x10000
        ? rune
        : 0xD800 + ((rune - 0x10000) >> 10); // High surrogate, as charCodeAt(0).
    h = (h ^ unit) & _mask32;
    h = (h * _prime) & _mask32;
  }
  return h;
}

/// mulberry32: a small seeded random number generator returning 0 to 1.
///
/// The state is kept as an unsigned 32-bit value; `| 0` and `Math.imul` in
/// the original work on the same low 32 bits, so the sequence matches the web
/// draw for draw for any seed.
final class SeededRandom {
  /// Creates a generator from any seed; only the seed's low 32 bits matter,
  /// exactly as `seed |= 0` in the original.
  SeededRandom(int seed) : _state = seed & _mask32;

  int _state;

  /// Returns the next number in [0, 1).
  double next() {
    _state = (_state + 0x6D2B79F5) & _mask32;
    var t = ((_state ^ (_state >> 15)) * (1 | _state)) & _mask32;
    final mixed = ((t ^ (t >> 7)) * (61 | t)) & _mask32;
    t = ((t + mixed) & _mask32) ^ t;
    return (t ^ (t >> 14)) / 4294967296;
  }

  /// Returns `floor(next() * count)`, the way the recipes pick an index.
  int nextIndex(int count) => (next() * count).floor();
}

/// Rounds to two decimal places, matching `Number(n.toFixed(2))` in rings.ts.
double round2(double value) => double.parse(value.toStringAsFixed(2));

/// One ring of a ring picture: a circle with one gap.
///
/// Mirrors `Arc` in rings.ts. [drawn] is the stroked part of the circle and
/// [gap] the rest of the circumference, both already rounded to two decimals
/// like the `stroke-dasharray` string on the web. [rotateDegrees] turns the
/// circle so the gaps don't line up. [end] is where an accent ring's arc
/// stops; its dot goes there.
final class RingArc {
  const RingArc({
    required this.radius,
    required this.drawn,
    required this.gap,
    required this.rotateDegrees,
    required this.accent,
    this.end,
  });

  /// Circle radius in viewBox units.
  final double radius;

  /// Length of the drawn part of the circle.
  final double drawn;

  /// Length of the gap in the circle.
  final double gap;

  /// Degrees to turn the circle from its 3 o'clock start.
  final double rotateDegrees;

  /// Whether this is the picture's one accent ring.
  final bool accent;

  /// Where the accent ring's arc ends, in viewBox units; its dot goes here.
  final Offset? end;

  /// The circle's full circumference.
  double get circumference => 2 * math.pi * radius;

  /// The drawn part as degrees, clockwise from the ring's start.
  double get drawnDegrees => 360 * drawn / circumference;
}

/// Circles around ([cx], [cy]), each with one gap.
///
/// Port of `arcs()` in rings.ts. The ring at [accent] gets the fixed
/// [accentGap] share as its gap and a dot where it ends; the rest draw their
/// gap share from [gapRange] (`min + random() * range`). Draws from [random]
/// in a fixed order — per ring, a gap draw unless it is the accent, then a
/// rotation draw — so the same seed always gives the same picture.
List<RingArc> seedArcs(
  SeededRandom random, {
  required double cx,
  required double cy,
  required List<double> radii,
  required int accent,
  required double accentGap,
  required (double, double) gapRange,
}) {
  final (gapMin, gapRangeWidth) = gapRange;
  return <RingArc>[
    for (final (index, radius) in radii.indexed)
      () {
        final circumference = 2 * math.pi * radius;
        final isAccent = index == accent;
        final gapShare = isAccent ? accentGap : gapMin + random.next() * gapRangeWidth;
        final rotate = random.next() * 360;
        final gap = round2(circumference * gapShare);
        final drawn = round2(circumference - circumference * gapShare);
        Offset? end;
        if (isAccent) {
          // The end angle uses the unrounded values, as on the web.
          final angle =
              rotate * math.pi / 180 + (circumference - circumference * gapShare) / radius;
          end = Offset(
            round2(cx + radius * math.cos(angle)),
            round2(cy + radius * math.sin(angle)),
          );
        }
        return RingArc(
          radius: radius,
          drawn: drawn,
          gap: gap,
          rotateDegrees: round2(rotate),
          accent: isAccent,
          end: end,
        );
      }(),
  ];
}

/// One half ring of the horizon picture: a circle broken into arcs.
///
/// Port of the arc rows `horizonArcs()` in ring-shapes.ts returns. The
/// accent ring is one long arc whose `end` is where the sun's path stops.
/// Segments carry start and sweep angles in radians, clockwise on screen;
/// the web builds path strings from the same numbers rounded at the
/// endpoints.
final class HorizonArc {
  const HorizonArc({
    required this.radius,
    required this.segments,
    required this.accent,
    this.end,
  });

  /// Circle radius in viewBox units.
  final double radius;

  /// (start angle, sweep angle) pairs in radians, clockwise on screen.
  final List<(double, double)> segments;

  /// Whether this is the sun's path.
  final bool accent;

  /// Where the sun's path stops, in viewBox units; its dot goes here.
  final Offset? end;
}

/// Draws the horizon picture's half rings for [seed].
///
/// Port of `horizonArcs()` in ring-shapes.ts; the draw order (start angle,
/// then per segment a span draw and a gap draw) matches the original so the
/// same seed gives the same picture.
List<HorizonArc> horizonArcs(
  String seed, {
  required double cx,
  required double cy,
  required List<double> radii,
  required int accent,
}) {
  final random = SeededRandom(hashName(seed) + 61);
  Offset point(double radius, double angle) => Offset(
    round2(cx + radius * math.cos(angle)),
    round2(cy + radius * math.sin(angle)),
  );
  return <HorizonArc>[
    for (final (index, radius) in radii.indexed)
      () {
        if (index == accent) {
          final to = math.pi * (1.42 + random.next() * 0.34);
          return HorizonArc(
            radius: radius,
            segments: <(double, double)>[(math.pi, to - math.pi)],
            accent: true,
            end: point(radius, to),
          );
        }
        double gap() => math.min(0.5, (10 + random.next() * 26) / radius);
        final segments = <(double, double)>[];
        var a = math.pi + random.next() * 0.06;
        while (a < 2 * math.pi - 0.05) {
          final span = 0.35 + random.next() * 1.4;
          final b = math.min(2 * math.pi, a + span);
          segments.add((a, b - a));
          a = b + gap();
        }
        return HorizonArc(radius: radius, segments: segments, accent: false);
      }(),
  ];
}

/// The horizon picture's stars, drawn from its own [seed] stream.
///
/// Matches the star block in the kits' `horizon-rings` component
/// (`rng(hash(seed) + 71)`, 14 stars).
List<(Offset, double)> horizonStars(String seed) {
  final random = SeededRandom(hashName(seed) + 71);
  return <(Offset, double)>[
    for (var i = 0; i < 14; i++)
      (
        Offset(30 + random.next() * 540, 18 + random.next() * 150),
        0.8 + random.next() * 1.3,
      ),
  ];
}
