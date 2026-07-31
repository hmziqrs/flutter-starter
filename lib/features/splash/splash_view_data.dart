import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:starter/features/splash/app_startup_result.dart';

part 'splash_view_data.freezed.dart';

enum SplashPhase { loading, done, error }

@freezed
class SplashViewData with _$SplashViewData {
  const SplashViewData({
    required this.phase,
    this.buildLabel,
    this.errorDiagnosticId,
  });

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

  @override
  final String? buildLabel;

  @override
  final String? errorDiagnosticId;
}

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
