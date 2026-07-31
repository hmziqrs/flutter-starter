import 'package:flutter/foundation.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';

@immutable
final class AppStartupResult {
  const AppStartupResult({
    required this.buildInfo,
    required this.settingsLoaded,
    required this.localeApplied,
    this.error,
  });

  final AppBuildInfo buildInfo;

  final bool settingsLoaded;

  final bool localeApplied;

  final AppStartupError? error;

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
