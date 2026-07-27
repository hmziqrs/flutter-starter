import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/shared/adaptive/app_unit.dart';

void main() {
  group('AppUnit', () {
    test('uses neutral scales at the reference width', () {
      final unit = AppUnit.fromSize(
        const Size(AppUnit.referenceWidth, 844),
        devicePixelRatio: 3,
      );

      expect(unit.spacingScale, 1);
      expect(unit.typographyScale, 1);
      expect(unit.sp(), AppUnit.baseSpace);
      expect(unit.un(16), 16);
      expect(unit.font(18), 18);
    });

    test('scales down and up within bounded ranges', () {
      final compact = AppUnit.fromSize(
        const Size(280, 700),
        devicePixelRatio: 2,
      );
      final expanded = AppUnit.fromSize(
        const Size(1600, 900),
        devicePixelRatio: 2,
      );

      expect(compact.spacingScale, AppUnit.minimumSpacingScale);
      expect(compact.typographyScale, AppUnit.minimumTypographyScale);
      expect(expanded.spacingScale, AppUnit.maximumSpacingScale);
      expect(expanded.typographyScale, AppUnit.maximumTypographyScale);
    });

    test('density does not change layout or typography scale', () {
      final lowDensity = AppUnit.fromSize(
        const Size(640, 900),
        devicePixelRatio: 1,
      );
      final highDensity = AppUnit.fromSize(
        const Size(640, 900),
        devicePixelRatio: 3,
      );

      expect(highDensity.spacingScale, lowDensity.spacingScale);
      expect(highDensity.typographyScale, lowDensity.typographyScale);
      expect(highDensity.un(24), lowDensity.un(24));
      expect(highDensity.font(18), lowDensity.font(18));
      expect(lowDensity.pixel, 1);
      expect(highDensity.pixel, closeTo(1 / 3, 0.0001));
      expect(highDensity.snap(1.2), closeTo(4 / 3, 0.0001));
    });

    test('rejects invalid width and density', () {
      expect(
        () => AppUnit.fromSize(
          const Size(double.infinity, 800),
          devicePixelRatio: 1,
        ),
        throwsArgumentError,
      );
      expect(
        () => AppUnit.fromSize(
          const Size(390, 800),
          devicePixelRatio: 0,
        ),
        throwsArgumentError,
      );
    });
  });
}
