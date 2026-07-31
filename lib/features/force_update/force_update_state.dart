import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:starter/features/force_update/update_requirement.dart';

part 'force_update_state.freezed.dart';

/// Immutable view data for the update-block UI (the hard-block page and the
/// soft-deprecation dialog), built from an [UpdateRequirement] via
/// [ForceUpdateState.from]. [storeUrl] is empty for `none` (never rendered).
@freezed
class ForceUpdateState with _$ForceUpdateState {
  const ForceUpdateState({
    required this.latestVersion,
    required this.storeUrl,
    this.message,
  });

  factory ForceUpdateState.from(UpdateRequirement requirement) {
    return switch (requirement) {
      UpdateRequirementNone() => const ForceUpdateState(
        latestVersion: '',
        storeUrl: '',
      ),
      UpdateRequirementSoft(
        :final latestVersion,
        :final storeUrl,
        :final message,
      ) =>
        ForceUpdateState(
          latestVersion: latestVersion,
          storeUrl: storeUrl,
          message: message,
        ),
      UpdateRequirementHard(
        :final latestVersion,
        :final storeUrl,
        :final message,
      ) =>
        ForceUpdateState(
          latestVersion: latestVersion,
          storeUrl: storeUrl,
          message: message,
        ),
    };
  }

  @override
  final String latestVersion;
  @override
  final String storeUrl;
  @override
  final String? message;
}
