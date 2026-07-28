import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/splash/app_startup_result.dart';
import 'package:starter/features/splash/splash_view_data.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';

void main() {
  group('SplashFixtures', () {
    test('exposes one deterministic fixture per phase', () {
      expect(SplashFixtures.loading.phase, SplashPhase.loading);
      expect(SplashFixtures.done.phase, SplashPhase.done);
      expect(SplashFixtures.error.phase, SplashPhase.error);

      expect(SplashFixtures.values, hasLength(3));
      // Fixtures are immutable value objects; reloading yields equal instances.
      expect(SplashFixtures.loading, SplashFixtures.loading);
    });

    test('the done fixture carries a deterministic build label', () {
      expect(SplashFixtures.done.buildLabel, '1.0.0+1');
    });

    test('the error fixture carries a diagnostic id', () {
      expect(SplashFixtures.error.errorDiagnosticId, 'STARTUP-UNKNOWN');
    });
  });

  group('SplashViewData.fromResult', () {
    test('maps a successful result to the done phase with the build label', () {
      const result = AppStartupResult(
        buildInfo: AppBuildInfo(version: '2.4.1', buildNumber: '42'),
        settingsLoaded: true,
        localeApplied: true,
      );

      final viewData = SplashViewData.fromResult(result);

      expect(viewData.phase, SplashPhase.done);
      expect(viewData.buildLabel, '2.4.1+42');
      expect(viewData.errorDiagnosticId, isNull);
    });

    test('maps a fatal error to the error phase with the diagnostic id', () {
      const result = AppStartupResult(
        buildInfo: AppBuildInfo(version: '1.0.0', buildNumber: '1'),
        settingsLoaded: false,
        localeApplied: false,
        error: AppStartupError(diagnosticId: 'STARTUP-CONFIG'),
      );

      final viewData = SplashViewData.fromResult(result);

      expect(viewData.phase, SplashPhase.error);
      expect(viewData.errorDiagnosticId, 'STARTUP-CONFIG');
      expect(viewData.buildLabel, isNull);
    });
  });

  group('SplashViewData equality', () {
    test('compares phase, build label, and diagnostic id', () {
      const a = SplashViewData(phase: SplashPhase.done, buildLabel: '1.0.0+1');
      const b = SplashViewData(phase: SplashPhase.done, buildLabel: '1.0.0+1');
      const c = SplashViewData(phase: SplashPhase.loading);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
    });
  });
}
