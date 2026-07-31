import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:starter/features/experiments/experiment_variant.dart';

part 'experiment_key.freezed.dart';

@freezed
abstract class ExperimentAllocation with _$ExperimentAllocation {
  @Assert('weight >= 0', 'ExperimentAllocation weight must be non-negative.')
  const factory ExperimentAllocation(ExperimentVariantKind variant, int weight) =
      _ExperimentAllocation;
}

enum ExperimentKey {
  paywallLayout(
    wireKey: 'paywall_layout',
    allocations: <ExperimentAllocation>[
      ExperimentAllocation(ExperimentVariantKind.control, 50),
      ExperimentAllocation(ExperimentVariantKind.treatmentA, 50),
    ],
  ),

  onboardingCta(
    wireKey: 'onboarding_cta',
    allocations: <ExperimentAllocation>[
      ExperimentAllocation(ExperimentVariantKind.control, 80),
      ExperimentAllocation(ExperimentVariantKind.treatmentA, 20),
    ],
  ),

  homeFeedOrder(
    wireKey: 'home_feed_order',
    allocations: <ExperimentAllocation>[
      ExperimentAllocation(ExperimentVariantKind.control, 70),
      ExperimentAllocation(ExperimentVariantKind.treatmentA, 20),
      ExperimentAllocation(ExperimentVariantKind.treatmentB, 10),
    ],
  );

  const ExperimentKey({required this.wireKey, required this.allocations});

  final String wireKey;

  final List<ExperimentAllocation> allocations;

  int get totalWeight => allocations.fold(0, (sum, allocation) => sum + allocation.weight);
}
