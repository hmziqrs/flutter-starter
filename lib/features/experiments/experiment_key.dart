import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:starter/features/experiments/experiment_variant.dart';

part 'experiment_key.freezed.dart';

/// A weighted entry in an [ExperimentKey]'s allocation table. [weight] is a
/// non-negative, relative share of the bucket space (a 50/50 split and a 5/5
/// split bucket identically) and need not sum to 100.
@freezed
abstract class ExperimentAllocation with _$ExperimentAllocation {
  @Assert('weight >= 0', 'ExperimentAllocation weight must be non-negative.')
  const factory ExperimentAllocation(ExperimentVariantKind variant, int weight) =
      _ExperimentAllocation;

  /// The variant arm this entry allocates traffic to.
  /// The relative share of the bucket space this arm receives.
}

/// Typed enum of the known experiments exposed by the experiments feature.
///
/// Adding an experiment: add a variant here with its backend [wireKey] and
/// [allocations] table — the deterministic source buckets it automatically,
/// the controller picks it up on the next refresh, and the diagnostics
/// snapshot surfaces it.
///
/// The allocation table is a fixed `const` list per experiment: the bucket is
/// a pure function of the stable device id and [wireKey], so a new experiment
/// never re-buckets an existing one.
enum ExperimentKey {
  /// Paywall layout refresh — 50/50 control vs treatmentA.
  paywallLayout(
    wireKey: 'paywall_layout',
    allocations: <ExperimentAllocation>[
      ExperimentAllocation(ExperimentVariantKind.control, 50),
      ExperimentAllocation(ExperimentVariantKind.treatmentA, 50),
    ],
  ),

  /// Onboarding call-to-action copy — 80% control, 20% treatmentA.
  onboardingCta(
    wireKey: 'onboarding_cta',
    allocations: <ExperimentAllocation>[
      ExperimentAllocation(ExperimentVariantKind.control, 80),
      ExperimentAllocation(ExperimentVariantKind.treatmentA, 20),
    ],
  ),

  /// Home feed ordering — 70% control, 20% treatmentA, 10% treatmentB.
  homeFeedOrder(
    wireKey: 'home_feed_order',
    allocations: <ExperimentAllocation>[
      ExperimentAllocation(ExperimentVariantKind.control, 70),
      ExperimentAllocation(ExperimentVariantKind.treatmentA, 20),
      ExperimentAllocation(ExperimentVariantKind.treatmentB, 10),
    ],
  );

  const ExperimentKey({required this.wireKey, required this.allocations});

  /// Backend wire key in the `experiments` slice of the remote-config payload.
  final String wireKey;

  /// The fixed allocation table the deterministic source buckets into.
  final List<ExperimentAllocation> allocations;

  /// The sum of every allocation weight for this experiment. The
  /// deterministic source takes the bucket modulo this value; a table
  /// summing to zero degrades to the control arm.
  int get totalWeight => allocations.fold(0, (sum, allocation) => sum + allocation.weight);
}
