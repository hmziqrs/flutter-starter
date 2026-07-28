import 'package:flutter/foundation.dart';

/// The finite set of variant kinds an `ExperimentKey` can allocate to.
///
/// This enum backs the per-experiment allocation table in
/// `lib/features/experiments/experiment_key.dart` and the wire decode in the
/// remote-config reader (`lib/infrastructure/remote_config/`), so the
/// deterministic default and the optional remote reader agree on names. New
/// variants are added here **and** as a sealed subtype of [ExperimentVariant]
/// in the same edit; the exhaustive switches over both (in
/// [ExperimentVariant.forKind], [ExperimentVariant.kindFromWireName], and every
/// consumer of the sealed family) make `flutter analyze --fatal-infos` fail if a
/// variant ships without a branch. This is the "no silent default branch"
/// safety rail required by the feature audit (item 7) and the spec's
/// "Variant exhaustiveness" risk note.
enum ExperimentVariantKind {
  /// The hold-out baseline. The deterministic default always falls back here
  /// when an allocation table is empty or a bucket cannot be resolved.
  control,

  /// First treatment arm.
  treatmentA,

  /// Second treatment arm.
  treatmentB,

  /// Third treatment arm.
  treatmentC,
}

/// A resolved variant for an experiment, carrying an immutable typed payload
/// map.
///
/// Sealed so consumer `switch` expressions over the variant family are
/// exhaustive: adding a new subtype (`ExperimentVariantTreatmentD`, …)
/// compile-fails every switch until each one gets a branch. This is the
/// load-bearing guardrail against a silent default branch — never weaken it by
/// switching on [kind] with a `default` case when the variant itself is what
/// the caller branches on; switch on the [ExperimentVariant] subtypes instead.
///
/// Each subtype has value equality over its [payload] so two assignments that
/// resolve the same arm with the same payload compare equal (mirrors
/// `FeatureFlags`). The [payload] is a `Map<String, Object?>` (the typed JSON
/// shape, never `dynamic`) so remote-config-supplied configuration is carried
/// without losing type discipline at the boundary.
sealed class ExperimentVariant {
  const ExperimentVariant({this.payload = const <String, Object?>{}});

  /// Backend-supplied configuration for this variant. Empty for the
  /// deterministic local default (no backend); populated by the optional remote
  /// reader from the `experiments` slice of the shared remote-config response.
  final Map<String, Object?> payload;

  /// The [ExperimentVariantKind] this subtype represents. Exhaustively
  /// implemented per subtype so the allocation table and wire decode stay in
  /// lockstep with the sealed family.
  ExperimentVariantKind get kind;

  /// Backend wire name (snake_case) used in the `experiments` slice and the
  /// diagnostics read-out. Stable across releases.
  String get wireName;

  /// Returns the [ExperimentVariant] subtype for [kind], carrying [payload].
  ///
  /// The exhaustive switch over [ExperimentVariantKind] guarantees a new kind
  /// cannot ship without a branch here. Used by the deterministic source (to
  /// materialize the bucketed arm) and the remote reader (to materialize the
  /// decoded arm with its payload).
  static ExperimentVariant forKind(
    ExperimentVariantKind kind, {
    Map<String, Object?> payload = const <String, Object?>{},
  }) {
    return switch (kind) {
      ExperimentVariantKind.control => ExperimentVariantControl(payload: payload),
      ExperimentVariantKind.treatmentA => ExperimentVariantTreatmentA(payload: payload),
      ExperimentVariantKind.treatmentB => ExperimentVariantTreatmentB(payload: payload),
      ExperimentVariantKind.treatmentC => ExperimentVariantTreatmentC(payload: payload),
    };
  }

  /// Parses [name] (a backend wire name) into a kind, accepting both snake_case
  /// (`treatment_a`) and lowerCamelCase (`treatmentA`) for tolerance. Returns
  /// `null` for an unrecognized name so callers degrade to the deterministic
  /// table rather than fabricating a variant (C2: never fake success).
  static ExperimentVariantKind? kindFromWireName(String? name) {
    return switch (name) {
      'control' => ExperimentVariantKind.control,
      'treatment_a' || 'treatmentA' => ExperimentVariantKind.treatmentA,
      'treatment_b' || 'treatmentB' => ExperimentVariantKind.treatmentB,
      'treatment_c' || 'treatmentC' => ExperimentVariantKind.treatmentC,
      _ => null,
    };
  }
}

/// The control (hold-out) arm.
@immutable
final class ExperimentVariantControl extends ExperimentVariant {
  /// Constructs a control variant with an optional [payload].
  const ExperimentVariantControl({super.payload});

  @override
  ExperimentVariantKind get kind => ExperimentVariantKind.control;

  @override
  String get wireName => 'control';

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is ExperimentVariantControl && _samePayload(other);
  }

  @override
  int get hashCode => Object.hash(ExperimentVariantKind.control, payload);

  bool _samePayload(ExperimentVariantControl other) {
    if (payload.length != other.payload.length) return false;
    for (final entry in payload.entries) {
      if (other.payload[entry.key] != entry.value) return false;
    }
    return true;
  }
}

/// The first treatment arm.
@immutable
final class ExperimentVariantTreatmentA extends ExperimentVariant {
  /// Constructs a treatmentA variant with an optional [payload].
  const ExperimentVariantTreatmentA({super.payload});

  @override
  ExperimentVariantKind get kind => ExperimentVariantKind.treatmentA;

  @override
  String get wireName => 'treatment_a';

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is ExperimentVariantTreatmentA && _samePayload(other);
  }

  @override
  int get hashCode => Object.hash(ExperimentVariantKind.treatmentA, payload);

  bool _samePayload(ExperimentVariantTreatmentA other) {
    if (payload.length != other.payload.length) return false;
    for (final entry in payload.entries) {
      if (other.payload[entry.key] != entry.value) return false;
    }
    return true;
  }
}

/// The second treatment arm.
@immutable
final class ExperimentVariantTreatmentB extends ExperimentVariant {
  /// Constructs a treatmentB variant with an optional [payload].
  const ExperimentVariantTreatmentB({super.payload});

  @override
  ExperimentVariantKind get kind => ExperimentVariantKind.treatmentB;

  @override
  String get wireName => 'treatment_b';

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is ExperimentVariantTreatmentB && _samePayload(other);
  }

  @override
  int get hashCode => Object.hash(ExperimentVariantKind.treatmentB, payload);

  bool _samePayload(ExperimentVariantTreatmentB other) {
    if (payload.length != other.payload.length) return false;
    for (final entry in payload.entries) {
      if (other.payload[entry.key] != entry.value) return false;
    }
    return true;
  }
}

/// The third treatment arm.
@immutable
final class ExperimentVariantTreatmentC extends ExperimentVariant {
  /// Constructs a treatmentC variant with an optional [payload].
  const ExperimentVariantTreatmentC({super.payload});

  @override
  ExperimentVariantKind get kind => ExperimentVariantKind.treatmentC;

  @override
  String get wireName => 'treatment_c';

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is ExperimentVariantTreatmentC && _samePayload(other);
  }

  @override
  int get hashCode => Object.hash(ExperimentVariantKind.treatmentC, payload);

  bool _samePayload(ExperimentVariantTreatmentC other) {
    if (payload.length != other.payload.length) return false;
    for (final entry in payload.entries) {
      if (other.payload[entry.key] != entry.value) return false;
    }
    return true;
  }
}
