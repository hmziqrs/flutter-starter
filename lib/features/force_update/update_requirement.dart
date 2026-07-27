import 'package:flutter/foundation.dart';

/// The outcome of comparing the installed build against the published version
/// policy.
///
/// Exhaustive `switch` over the three subtypes is required at every call site
/// (the `go_router` redirect, the dev-gallery fixtures, and the mapping to the
/// force-update view data) so every branch is handled explicitly. The honest
/// no-backend default is [UpdateRequirementNone] — a missing policy source must
/// never fabricate a hard or soft block (C2: never fake success).
sealed class UpdateRequirement {
  const UpdateRequirement();
}

/// No update action is required.
final class UpdateRequirementNone extends UpdateRequirement {
  const UpdateRequirementNone();
}

/// A deprecated build that should update but must not be blocked. Surfaced as a
/// dismissible soft dialog with a snooze path; never as a redirect.
@immutable
final class UpdateRequirementSoft extends UpdateRequirement {
  const UpdateRequirementSoft({
    required this.minVersion,
    required this.latestVersion,
    required this.storeUrl,
    this.message,
  });

  /// The lowest version that avoids the soft deprecation.
  final String minVersion;

  /// The newest published version.
  final String latestVersion;

  /// Store deep-link opened by the "Update" action.
  final String storeUrl;

  /// Optional server-supplied message; rendered verbatim when present.
  final String? message;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is UpdateRequirementSoft &&
            minVersion == other.minVersion &&
            latestVersion == other.latestVersion &&
            storeUrl == other.storeUrl &&
            message == other.message;
  }

  @override
  int get hashCode => Object.hash(minVersion, latestVersion, storeUrl, message);
}

/// A blocked build that must update before it can continue. Surfaced as a
/// non-dismissible full-screen page and a top-level redirect.
@immutable
final class UpdateRequirementHard extends UpdateRequirement {
  const UpdateRequirementHard({
    required this.minVersion,
    required this.latestVersion,
    required this.storeUrl,
    this.message,
  });

  /// The lowest version that clears the hard block.
  final String minVersion;

  /// The newest published version.
  final String latestVersion;

  /// Store deep-link opened by the "Update now" action.
  final String storeUrl;

  /// Optional server-supplied message; rendered verbatim when present.
  final String? message;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is UpdateRequirementHard &&
            minVersion == other.minVersion &&
            latestVersion == other.latestVersion &&
            storeUrl == other.storeUrl &&
            message == other.message;
  }

  @override
  int get hashCode => Object.hash(minVersion, latestVersion, storeUrl, message);
}
