import 'package:flutter_test/flutter_test.dart';
import 'package:starter/shared/adaptive/app_layout_class.dart';

void main() {
  const compactMax = 640.0;
  const expandedMin = 1024.0;

  group('AppLayoutClass.fromWidth', () {
    test('selects compact below the compact threshold', () {
      expect(
        AppLayoutClass.fromWidth(
          639.999,
          compactMax: compactMax,
          expandedMin: expandedMin,
        ),
        AppLayoutClass.compact,
      );
    });

    test('selects medium at and between the thresholds', () {
      expect(
        AppLayoutClass.fromWidth(
          compactMax,
          compactMax: compactMax,
          expandedMin: expandedMin,
        ),
        AppLayoutClass.medium,
      );
      expect(
        AppLayoutClass.fromWidth(
          1023.999,
          compactMax: compactMax,
          expandedMin: expandedMin,
        ),
        AppLayoutClass.medium,
      );
    });

    test('selects expanded at and above the expanded threshold', () {
      expect(
        AppLayoutClass.fromWidth(
          expandedMin,
          compactMax: compactMax,
          expandedMin: expandedMin,
        ),
        AppLayoutClass.expanded,
      );
      expect(
        AppLayoutClass.fromWidth(
          1440,
          compactMax: compactMax,
          expandedMin: expandedMin,
        ),
        AppLayoutClass.expanded,
      );
    });

    test('accepts zero as a valid available width', () {
      expect(
        AppLayoutClass.fromWidth(
          0,
          compactMax: compactMax,
          expandedMin: expandedMin,
        ),
        AppLayoutClass.compact,
      );
    });

    test('rejects a non-positive or non-finite compact threshold', () {
      for (final invalidCompactMax in <double>[0, -1, double.nan, double.infinity]) {
        expect(
          () => AppLayoutClass.fromWidth(
            800,
            compactMax: invalidCompactMax,
            expandedMin: expandedMin,
          ),
          throwsArgumentError,
        );
      }
    });

    test('rejects an unordered or non-finite expanded threshold', () {
      for (final invalidExpandedMin in <double>[
        compactMax - 1,
        compactMax,
        double.nan,
        double.infinity,
      ]) {
        expect(
          () => AppLayoutClass.fromWidth(
            800,
            compactMax: compactMax,
            expandedMin: invalidExpandedMin,
          ),
          throwsArgumentError,
        );
      }
    });

    test('rejects a negative or non-finite available width', () {
      for (final invalidWidth in <double>[-1, double.nan, double.infinity]) {
        expect(
          () => AppLayoutClass.fromWidth(
            invalidWidth,
            compactMax: compactMax,
            expandedMin: expandedMin,
          ),
          throwsArgumentError,
        );
      }
    });
  });
}
