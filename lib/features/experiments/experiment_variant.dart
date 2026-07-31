import 'package:freezed_annotation/freezed_annotation.dart';

part 'experiment_variant.freezed.dart';

enum ExperimentVariantKind {
  control,

  treatmentA,

  treatmentB,

  treatmentC,
}

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

  ExperimentVariantKind get kind => switch (this) {
    ExperimentVariantControl() => ExperimentVariantKind.control,
    ExperimentVariantTreatmentA() => ExperimentVariantKind.treatmentA,
    ExperimentVariantTreatmentB() => ExperimentVariantKind.treatmentB,
    ExperimentVariantTreatmentC() => ExperimentVariantKind.treatmentC,
  };

  String get wireName => switch (this) {
    ExperimentVariantControl() => 'control',
    ExperimentVariantTreatmentA() => 'treatment_a',
    ExperimentVariantTreatmentB() => 'treatment_b',
    ExperimentVariantTreatmentC() => 'treatment_c',
  };

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
