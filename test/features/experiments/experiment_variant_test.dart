import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/experiments/experiment_variant.dart';

void main() {
  group('ExperimentVariantKind', () {
    test('has four arms', () {
      expect(ExperimentVariantKind.values, hasLength(4));
    });

    test('wireName round-trips through kindFromWireName (snake_case)', () {
      for (final kind in ExperimentVariantKind.values) {
        final variant = ExperimentVariant.forKind(kind);
        expect(ExperimentVariant.kindFromWireName(variant.wireName), kind);
      }
    });
  });

  group('ExperimentVariant.forKind', () {
    test('returns the matching subtype for every kind', () {
      expect(
        ExperimentVariant.forKind(ExperimentVariantKind.control),
        isA<ExperimentVariantControl>(),
      );
      expect(
        ExperimentVariant.forKind(ExperimentVariantKind.treatmentA),
        isA<ExperimentVariantTreatmentA>(),
      );
      expect(
        ExperimentVariant.forKind(ExperimentVariantKind.treatmentB),
        isA<ExperimentVariantTreatmentB>(),
      );
      expect(
        ExperimentVariant.forKind(ExperimentVariantKind.treatmentC),
        isA<ExperimentVariantTreatmentC>(),
      );
    });

    test('carries the supplied payload', () {
      const payload = <String, Object?>{'ratio': 0.5, 'label': 'v1'};
      final variant = ExperimentVariant.forKind(
        ExperimentVariantKind.treatmentA,
        payload: payload,
      );
      expect(variant.payload, payload);
    });

    test('defaults to an empty payload', () {
      expect(
        ExperimentVariant.forKind(ExperimentVariantKind.control).payload,
        isEmpty,
      );
    });
  });

  group('ExperimentVariant.kindFromWireName', () {
    test('accepts snake_case and lowerCamelCase', () {
      expect(
        ExperimentVariant.kindFromWireName('treatment_a'),
        ExperimentVariantKind.treatmentA,
      );
      expect(
        ExperimentVariant.kindFromWireName('treatmentA'),
        ExperimentVariantKind.treatmentA,
      );
      expect(
        ExperimentVariant.kindFromWireName('control'),
        ExperimentVariantKind.control,
      );
    });

    test('returns null for an unknown name so callers degrade', () {
      expect(ExperimentVariant.kindFromWireName('arm_z'), isNull);
      expect(ExperimentVariant.kindFromWireName(null), isNull);
      expect(ExperimentVariant.kindFromWireName(''), isNull);
    });
  });

  group('ExperimentVariant value equality', () {
    test('same kind + same payload are equal', () {
      const payload = <String, Object?>{'a': 1};
      expect(
        ExperimentVariant.forKind(ExperimentVariantKind.control, payload: payload),
        ExperimentVariant.forKind(ExperimentVariantKind.control, payload: payload),
      );
    });

    test('same kind + different payload are not equal', () {
      expect(
        ExperimentVariant.forKind(
          ExperimentVariantKind.control,
          payload: const <String, Object?>{'a': 1},
        ),
        isNot(
          ExperimentVariant.forKind(
            ExperimentVariantKind.control,
            payload: const <String, Object?>{'a': 2},
          ),
        ),
      );
    });

    test('different kinds are not equal', () {
      expect(
        ExperimentVariant.forKind(ExperimentVariantKind.control),
        isNot(ExperimentVariant.forKind(ExperimentVariantKind.treatmentA)),
      );
    });

    test('payload equality is order-insensitive over keys', () {
      expect(
        ExperimentVariant.forKind(
          ExperimentVariantKind.treatmentB,
          payload: const <String, Object?>{'a': 1, 'b': 2},
        ),
        ExperimentVariant.forKind(
          ExperimentVariantKind.treatmentB,
          payload: const <String, Object?>{'b': 2, 'a': 1},
        ),
      );
    });
  });

  group('sealed family exhaustiveness', () {
    test('a switch over ExperimentVariant covers every subtype', () {
      String label(ExperimentVariant variant) {
        return switch (variant) {
          ExperimentVariantControl() => 'control',
          ExperimentVariantTreatmentA() => 'a',
          ExperimentVariantTreatmentB() => 'b',
          ExperimentVariantTreatmentC() => 'c',
        };
      }

      expect(label(const ExperimentVariantControl()), 'control');
      expect(label(const ExperimentVariantTreatmentA()), 'a');
      expect(label(const ExperimentVariantTreatmentB()), 'b');
      expect(label(const ExperimentVariantTreatmentC()), 'c');
    });
  });
}
