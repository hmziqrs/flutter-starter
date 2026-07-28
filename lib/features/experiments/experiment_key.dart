import 'package:flutter/foundation.dart';
import 'package:starter/features/experiments/experiment_variant.dart';

/// A weighted entry in an [ExperimentKey]'s allocation table.
///
/// [weight] is a non-negative share of the deterministic bucket space; the
/// deterministic experiment source sums the weights per experiment and picks
/// the arm whose cumulative range covers the hashed bucket. Weights are
/// relative (a 50/50 split and a 5/5 split bucket identically) and need not
/// sum to 100.
@immutable
final class ExperimentAllocation {
  /// Constructs an allocation for [variant] with the given [weight].
  const ExperimentAllocation(this.variant, this.weight)
    : assert(weight >= 0, 'ExperimentAllocation weight must be non-negative.');

  /// The variant arm this entry allocates traffic to.
  final ExperimentVariantKind variant;

  /// The relative share of the bucket space this arm receives.
  final int weight;
}

/// Typed enum of the known experiments exposed by the experiments feature.
///
/// Adding an experiment is a four-step, analysis-checked edit:
/// 1. add a variant here with its backend [wireKey] and [allocations] table;
/// 2. the deterministic source buckets it automatically (no per-key code);
/// 3. the controller refreshes it on the next cycle (it iterates
///    [ExperimentKey.values]);
/// 4. the diagnostics snapshot surfaces it under `developmentToolsEnabled`.
///
/// The allocation table is a fixed `const` list per experiment so the
/// deterministic default is reproducible across launches and platforms (the
/// bucket is a pure function of the stable device id and the experiment's
/// [wireKey]). A new experiment never re-buckets existing ones because the hash
/// input is scoped per [wireKey].
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

  /// The sum of every allocation weight for this experiment. The deterministic
  /// source takes the bucket modulo this value; an experiment whose table sums
  /// to zero degrades to the control arm (defensive — the const tables above are
  /// all non-zero).
  int get totalWeight {
    var total = 0;
    for (final allocation in allocations) {
      total += allocation.weight;
    }
    return total;
  }
}
