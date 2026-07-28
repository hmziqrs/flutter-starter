import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/experiments/experiment_key.dart';
import 'package:starter/features/experiments/experiment_variant.dart';

void main() {
  group('ExperimentKey', () {
    test('every experiment declares a non-empty allocation table', () {
      for (final key in ExperimentKey.values) {
        expect(key.allocations, isNotEmpty, reason: '$key has no allocations');
      }
    });

    test('every allocation table has a positive total weight', () {
      for (final key in ExperimentKey.values) {
        expect(key.totalWeight, greaterThan(0), reason: '$key sums to zero');
      }
    });

    test('every allocation weight is non-negative', () {
      for (final key in ExperimentKey.values) {
        for (final allocation in key.allocations) {
          expect(allocation.weight, greaterThanOrEqualTo(0));
        }
      }
    });

    test('wire keys are unique across experiments', () {
      final keys = <String>{};
      for (final key in ExperimentKey.values) {
        expect(keys, isNot(contains(key.wireKey)), reason: 'duplicate wireKey');
        keys.add(key.wireKey);
      }
    });

    test('paywallLayout is a 50/50 control/treatmentA split', () {
      const key = ExperimentKey.paywallLayout;
      expect(key.totalWeight, 100);
      expect(
        key.allocations,
        [
          const ExperimentAllocation(ExperimentVariantKind.control, 50),
          const ExperimentAllocation(ExperimentVariantKind.treatmentA, 50),
        ],
      );
    });

    test('totalWeight sums the allocation weights', () {
      expect(ExperimentKey.homeFeedOrder.totalWeight, 100);
      expect(ExperimentKey.onboardingCta.totalWeight, 100);
    });
  });

  group('ExperimentAllocation', () {
    test('stores its variant and weight', () {
      const allocation = ExperimentAllocation(ExperimentVariantKind.treatmentB, 30);
      expect(allocation.variant, ExperimentVariantKind.treatmentB);
      expect(allocation.weight, 30);
    });

    test('rejects a negative weight at construction', () {
      expect(
        () => ExperimentAllocation(ExperimentVariantKind.control, -1),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
