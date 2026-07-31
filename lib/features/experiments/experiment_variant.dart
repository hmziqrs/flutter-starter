import 'package:freezed_annotation/freezed_annotation.dart';

part 'experiment_variant.freezed.dart';

/// The finite set of variant kinds an `ExperimentKey` can allocate to. Backs
/// the per-experiment allocation table and the wire decode in the
/// remote-config reader, so both agree on names. New variants must be added
/// here **and** as a sealed subtype of [ExperimentVariant] in the same edit;
/// the exhaustive switches over both (in [ExperimentVariant.forKind],
/// [ExperimentVariant.kindFromWireName], and every consumer) fail analysis if
/// a variant ships without a branch.
enum ExperimentVariantKind {
  /// The hold-out baseline. The deterministic default falls back here when
  /// an allocation table is empty or a bucket cannot be resolved.
  control,

  /// First treatment arm.
  treatmentA,

  /// Second treatment arm.
  treatmentB,

  /// Third treatment arm.
  treatmentC,
}

/// A resolved variant for an experiment, carrying an immutable typed payload
/// map. Sealed so consumer `switch` expressions over the variant family are
/// exhaustive: adding a subtype compile-fails every switch until it gets a
/// branch — never weaken this by switching on [kind] with a `default` case;
/// switch on the [ExperimentVariant] subtypes instead.
///
/// Each subtype has value equality over its [payload].
@freezed
sealed class ExperimentVariant with _$ExperimentVariant {
  const factory ExperimentVariant.control({
    @Default(<String, Object?>{}) Map<String, Object?> payload,
  }) = ExperimentVariantControl;

  const factory ExperimentVariant.treatmentA({
    @Default(<String, Object?>{}) Map<String, Object?> payload,
  }) = ExperimentVariantTreatmentA;

  const factory ExperimentVariant.treatmentB({
    @Default(<String, Object?>{}) Map<String, Object?> payload,
  }) = ExperimentVariantTreatmentB;

  const factory ExperimentVariant.treatmentC({
    @Default(<String, Object?>{}) Map<String, Object?> payload,
  }) = ExperimentVariantTreatmentC;

  const ExperimentVariant._();

  /// Backend-supplied configuration for this variant. Empty for the
  /// deterministic local default; populated by the optional remote reader.
  /// The [ExperimentVariantKind] this subtype represents.
  ExperimentVariantKind get kind => switch (this) {
    ExperimentVariantControl() => ExperimentVariantKind.control,
    ExperimentVariantTreatmentA() => ExperimentVariantKind.treatmentA,
    ExperimentVariantTreatmentB() => ExperimentVariantKind.treatmentB,
    ExperimentVariantTreatmentC() => ExperimentVariantKind.treatmentC,
  };

  /// Backend wire name (snake_case) used in the `experiments` slice and the
  /// diagnostics read-out.
  String get wireName => switch (this) {
    ExperimentVariantControl() => 'control',
    ExperimentVariantTreatmentA() => 'treatment_a',
    ExperimentVariantTreatmentB() => 'treatment_b',
    ExperimentVariantTreatmentC() => 'treatment_c',
  };

  /// Returns the [ExperimentVariant] subtype for [kind], carrying [payload].
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

  /// Parses [name] (a backend wire name) into a kind, accepting both
  /// snake_case and lowerCamelCase. Returns `null` for an unrecognized name so
  /// callers degrade to the deterministic table.
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
