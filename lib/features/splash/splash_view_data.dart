import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:starter/features/splash/app_startup_result.dart';

part 'splash_view_data.freezed.dart';

/// The presentation phases the splash surface renders.
enum SplashPhase { loading, done, error }

/// Immutable, fixture-friendly view data for the splash surface. The
/// production SplashPage derives it from the watched AppStartupResult future;
/// the development gallery constructs it directly via [SplashFixtures].
@freezed
class SplashViewData with _$SplashViewData {
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

  @override
  final SplashPhase phase;

  /// Optional build label (e.g. `1.0.0+1`) shown on the `done` phase.
  @override
  final String? buildLabel;

  /// Optional diagnostic id shown on the `error` phase, reused from
  /// `startupDiagnosticIdFor` so the error styling stays consistent.
  @override
  final String? errorDiagnosticId;
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
