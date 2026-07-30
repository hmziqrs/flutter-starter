import 'package:flutter/foundation.dart';

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
sealed class ExperimentVariant {
  const ExperimentVariant({this.payload = const <String, Object?>{}});

  /// Backend-supplied configuration for this variant. Empty for the
  /// deterministic local default; populated by the optional remote reader.
  final Map<String, Object?> payload;

  /// The [ExperimentVariantKind] this subtype represents.
  ExperimentVariantKind get kind;

  /// Backend wire name (snake_case) used in the `experiments` slice and the
  /// diagnostics read-out.
  String get wireName;

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

/// The control (hold-out) arm.
@immutable
final class ExperimentVariantControl extends ExperimentVariant {
  const ExperimentVariantControl({super.payload});

  @override
  ExperimentVariantKind get kind => ExperimentVariantKind.control;

  @override
  String get wireName => 'control';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExperimentVariantControl && _payloadEquals(payload, other.payload);

  @override
  int get hashCode => Object.hash(ExperimentVariantKind.control, payload);
}

/// The first treatment arm.
@immutable
final class ExperimentVariantTreatmentA extends ExperimentVariant {
  const ExperimentVariantTreatmentA({super.payload});

  @override
  ExperimentVariantKind get kind => ExperimentVariantKind.treatmentA;

  @override
  String get wireName => 'treatment_a';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExperimentVariantTreatmentA && _payloadEquals(payload, other.payload);

  @override
  int get hashCode => Object.hash(ExperimentVariantKind.treatmentA, payload);
}

/// The second treatment arm.
@immutable
final class ExperimentVariantTreatmentB extends ExperimentVariant {
  const ExperimentVariantTreatmentB({super.payload});

  @override
  ExperimentVariantKind get kind => ExperimentVariantKind.treatmentB;

  @override
  String get wireName => 'treatment_b';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExperimentVariantTreatmentB && _payloadEquals(payload, other.payload);

  @override
  int get hashCode => Object.hash(ExperimentVariantKind.treatmentB, payload);
}

/// The third treatment arm.
@immutable
final class ExperimentVariantTreatmentC extends ExperimentVariant {
  const ExperimentVariantTreatmentC({super.payload});

  @override
  ExperimentVariantKind get kind => ExperimentVariantKind.treatmentC;

  @override
  String get wireName => 'treatment_c';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExperimentVariantTreatmentC && _payloadEquals(payload, other.payload);

  @override
  int get hashCode => Object.hash(ExperimentVariantKind.treatmentC, payload);
}

/// Shared payload-map equality for the [ExperimentVariant] subtypes.
bool _payloadEquals(Map<String, Object?> a, Map<String, Object?> b) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}
