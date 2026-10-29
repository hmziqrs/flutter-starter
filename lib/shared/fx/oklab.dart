import 'dart:math' as math;
import 'dart:ui' show Color;

/// OKLab color mixing, matching the CSS `color-mix(in oklab, a t%, b)`
/// the brand kit's stylesheets use (glass.css's tint wash, materials.css's
/// sheet floor). sRGB components go through the standard OKLab transform
/// (Björn Ottosson), mix there, and convert back.
///
/// [t] is the share of [b] in the mix (0 gives [a], 1 gives [b]); both
/// colors' alphas mix linearly, the way the CSS spec composites them.
Color oklabMix(Color a, Color b, double t) {
  final labA = _linearSrgbToOklab(_srgbToLinear(a));
  final labB = _linearSrgbToOklab(_srgbToLinear(b));
  final mixed = (
    labA.$1 + (labB.$1 - labA.$1) * t,
    labA.$2 + (labB.$2 - labA.$2) * t,
    labA.$3 + (labB.$3 - labA.$3) * t,
  );
  final rgb = _oklabToLinearSrgb(mixed);
  return Color.fromARGB(
    ((a.a + (b.a - a.a) * t) * 255).round().clamp(0, 255),
    (_linearToSrgbChannel(rgb.$1) * 255).round().clamp(0, 255),
    (_linearToSrgbChannel(rgb.$2) * 255).round().clamp(0, 255),
    (_linearToSrgbChannel(rgb.$3) * 255).round().clamp(0, 255),
  );
}

(double, double, double) _srgbToLinear(Color color) {
  double channel(double value) =>
      value <= 0.04045 ? value / 12.92 : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  return (channel(color.r), channel(color.g), channel(color.b));
}

(double, double, double) _linearSrgbToOklab((double, double, double) rgb) {
  final (r, g, b) = rgb;
  final l = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b;
  final m = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b;
  final s = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b;
  final lRoot = math.pow(l, 1 / 3).toDouble();
  final mRoot = math.pow(m, 1 / 3).toDouble();
  final sRoot = math.pow(s, 1 / 3).toDouble();
  return (
    0.2104542553 * lRoot + 0.793617785 * mRoot - 0.0040720468 * sRoot,
    1.9779984951 * lRoot - 2.428592205 * mRoot + 0.4505937099 * sRoot,
    0.0259040371 * lRoot + 0.7827717662 * mRoot - 0.808675766 * sRoot,
  );
}

(double, double, double) _oklabToLinearSrgb((double, double, double) lab) {
  final (lightness, aStar, bStar) = lab;
  final lPrime = lightness + 0.3963377774 * aStar + 0.2158037573 * bStar;
  final mPrime = lightness - 0.1055613458 * aStar - 0.0638541728 * bStar;
  final sPrime = lightness - 0.0894841775 * aStar - 1.291485548 * bStar;
  final l = lPrime * lPrime * lPrime;
  final m = mPrime * mPrime * mPrime;
  final s = sPrime * sPrime * sPrime;
  return (
    4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
    -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
    -0.0041960863 * l - 0.7034186147 * m + 1.707614701 * s,
  );
}

double _linearToSrgbChannel(double value) {
  final v = value.clamp(0.0, 1.0);
  return v <= 0.0031308 ? v * 12.92 : 1.055 * math.pow(v, 1 / 2.4).toDouble() - 0.055;
}
