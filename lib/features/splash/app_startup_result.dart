import 'package:flutter/foundation.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';

/// A typed, immutable summary of the startup work `createApplication` already
/// performs (build-info load, settings load, locale apply). Carried out of the
/// composition root so SplashPage can observe the existing init future
/// without re-running any of it (the canonical splash mistake).
///
/// `error` is non-null only when a fatal init step could not be recovered. The
/// production composition root currently swallows settings/locale failures into
/// safe defaults, so a successful cold start yields `isSuccess == true` with
/// the individual `settingsLoaded` / `localeApplied` flags recording whether the
/// persisted values were honored.
@immutable
final class AppStartupResult {
  const AppStartupResult({
    required this.buildInfo,
    required this.settingsLoaded,
    required this.localeApplied,
    this.error,
  });

  /// Build metadata loaded once in the composition root.
  final AppBuildInfo buildInfo;

  /// Whether persisted settings loaded successfully (false when the repository
  /// fell back to safe defaults after a read failure).
  final bool settingsLoaded;

  /// Whether the persisted locale was applied (false when the device locale was
  /// used instead, or the apply call failed).
  final bool localeApplied;

  /// A fatal startup error, if one occurred. Null on success.
  final AppStartupError? error;

  /// `true` when [error] is null.
  bool get isSuccess => error == null;

  AppStartupResult copyWith({
    AppBuildInfo? buildInfo,
    bool? settingsLoaded,
    bool? localeApplied,
    AppStartupError? error,
  }) {
    return AppStartupResult(
      buildInfo: buildInfo ?? this.buildInfo,
      settingsLoaded: settingsLoaded ?? this.settingsLoaded,
      localeApplied: localeApplied ?? this.localeApplied,
      error: error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AppStartupResult &&
            buildInfo.version == other.buildInfo.version &&
            buildInfo.buildNumber == other.buildInfo.buildNumber &&
            settingsLoaded == other.settingsLoaded &&
            localeApplied == other.localeApplied &&
            error == other.error;
  }

  @override
  int get hashCode =>
      Object.hash(buildInfo.version, buildInfo.buildNumber, settingsLoaded, localeApplied, error);
}

/// A typed startup error surfaced from the composition root. The
/// [diagnosticId] mirrors the codes produced by `startupDiagnosticIdFor` so the
/// splash error state can reuse the startup-error styling verbatim.
@immutable
final class AppStartupError {
  const AppStartupError({required this.diagnosticId, this.message});

  final String diagnosticId;
  final String? message;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AppStartupError && diagnosticId == other.diagnosticId && message == other.message;
  }

  @override
  int get hashCode => Object.hash(diagnosticId, message);
}
