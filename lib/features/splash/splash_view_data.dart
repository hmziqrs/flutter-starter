import 'package:flutter/foundation.dart';
import 'package:starter/features/splash/app_startup_result.dart';

/// The presentation phases the splash surface renders.
enum SplashPhase { loading, done, error }

/// Immutable, fixture-friendly view data for the splash surface. The
/// production SplashPage derives it from the watched AppStartupResult future;
/// the development gallery constructs it directly via [SplashFixtures].
@immutable
final class SplashViewData {
  const SplashViewData({
    required this.phase,
    this.buildLabel,
    this.errorDiagnosticId,
  });

  /// Maps a resolved [AppStartupResult] to its presentation phase.
  factory SplashViewData.fromResult(AppStartupResult result) {
    if (result.error case final error?) {
      return SplashViewData(
        phase: SplashPhase.error,
        errorDiagnosticId: error.diagnosticId,
      );
    }
    return SplashViewData(
      phase: SplashPhase.done,
      buildLabel: result.buildInfo.displayValue,
    );
  }

  final SplashPhase phase;

  /// Optional build label (e.g. `1.0.0+1`) shown on the `done` phase.
  final String? buildLabel;

  /// Optional diagnostic id shown on the `error` phase, reused from
  /// `startupDiagnosticIdFor` so the error styling stays consistent.
  final String? errorDiagnosticId;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SplashViewData &&
            phase == other.phase &&
            buildLabel == other.buildLabel &&
            errorDiagnosticId == other.errorDiagnosticId;
  }

  @override
  int get hashCode => Object.hash(phase, buildLabel, errorDiagnosticId);
}

/// Deterministic, immutable gallery fixtures, one per [SplashPhase].
abstract final class SplashFixtures {
  static const loading = SplashViewData(phase: SplashPhase.loading);

  static const done = SplashViewData(
    phase: SplashPhase.done,
    buildLabel: '1.0.0+1',
  );

  static const error = SplashViewData(
    phase: SplashPhase.error,
    errorDiagnosticId: 'STARTUP-UNKNOWN',
  );

  static const values = <SplashViewData>[loading, done, error];
}
