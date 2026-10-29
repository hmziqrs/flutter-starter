import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:starter/shared/fx/oklab.dart';

void main() {
  group('oklabMix', () {
    const white = Color(0xFFFFFFFF);
    const black = Color(0xFF000000);
    // The glass tint wash's own mix: 16% oxide orange into the dark page.
    const primary = Color(0xFFF38230);
    const darkBackground = Color(0xFF121212);

    test('endpoints are the inputs', () {
      expect(oklabMix(white, black, 0), white);
      expect(oklabMix(white, black, 1), black);
    });

    test('mid grey mixes to the OKLab midpoint', () {
      // L 0.5 -> linear 0.125 -> sRGB ~0.3885 per channel.
      final mid = oklabMix(white, black, 0.5);
      expect(mid.r, moreOrLessEquals(0.3885, epsilon: 0.01));
      expect(mid.g, moreOrLessEquals(0.3885, epsilon: 0.01));
      expect(mid.b, moreOrLessEquals(0.3885, epsilon: 0.01));
    });

    test('hue survives a small mix, unlike an sRGB lerp', () {
      final mixed = oklabMix(darkBackground, primary, 0.16);
      // The mixed hue leans orange: red clearly above green above blue.
      expect(mixed.r, greaterThan(mixed.g));
      expect(mixed.g, greaterThan(mixed.b));
      // And it stays near the page color: not even a quarter of the way in
      // an sRGB reading.
      expect(mixed.r, lessThan(0.45));
    });

    test('alphas mix linearly', () {
      const half = Color(0x80FFFFFF);
      final mixed = oklabMix(black, half, 1);
      expect(mixed.a, moreOrLessEquals(128 / 255, epsilon: 1 / 255));
    });
  });
}
