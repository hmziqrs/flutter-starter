import 'package:freezed_annotation/freezed_annotation.dart';

part 'update_requirement.freezed.dart';

@freezed
sealed class UpdateRequirement with _$UpdateRequirement {
  const factory UpdateRequirement.none() = UpdateRequirementNone;

  const factory UpdateRequirement.soft({
    required String minVersion,
    required String latestVersion,
    required String storeUrl,
    String? message,
  }) = UpdateRequirementSoft;

  const factory UpdateRequirement.hard({
    required String minVersion,
    required String latestVersion,
    required String storeUrl,
    String? message,
  }) = UpdateRequirementHard;
}
