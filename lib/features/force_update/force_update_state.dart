import 'package:flutter/foundation.dart';
import 'package:starter/features/force_update/update_requirement.dart';

/// Immutable view data for the update-block UI (the hard-block page and the
/// soft-deprecation dialog).
///
/// Constructed from an [UpdateRequirement] via [ForceUpdateState.from]; the
/// redirect and gallery fixtures never read the requirement's payload directly.
/// [storeUrl] is non-empty for `soft` / `hard`; for `none` it is empty (the page
/// is not shown for `none`, so the empty value is never rendered).
@immutable
final class ForceUpdateState {
  const ForceUpdateState({
    required this.latestVersion,
    required this.storeUrl,
    this.message,
  });

  /// Builds the view data for [requirement], mapping each subtype explicitly.
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

  final String latestVersion;
  final String storeUrl;
  final String? message;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ForceUpdateState &&
            latestVersion == other.latestVersion &&
            storeUrl == other.storeUrl &&
            message == other.message;
  }

  @override
  int get hashCode => Object.hash(latestVersion, storeUrl, message);
}
