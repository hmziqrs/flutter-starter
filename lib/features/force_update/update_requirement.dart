import 'package:freezed_annotation/freezed_annotation.dart';

part 'update_requirement.freezed.dart';

/// The outcome of comparing the installed build against the published version
/// policy. The no-backend default is [UpdateRequirementNone] — a missing
/// policy source must never fabricate a hard or soft block.
@freezed
sealed class UpdateRequirement with _$UpdateRequirement {
  /// No update action is required.
  const factory UpdateRequirement.none() = UpdateRequirementNone;

  /// A deprecated build that should update but must not be blocked. Surfaced as
  /// a dismissible soft dialog with a snooze path; never as a redirect.
  const factory UpdateRequirement.soft({
    required String minVersion,
    required String latestVersion,
    required String storeUrl,
    String? message,
  }) = UpdateRequirementSoft;

  /// A blocked build that must update before it can continue. Surfaced as a
  /// non-dismissible full-screen page and a top-level redirect.
  const factory UpdateRequirement.hard({
    required String minVersion,
    required String latestVersion,
    required String storeUrl,
    String? message,
  }) = UpdateRequirementHard;
}
