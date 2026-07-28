import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/splash/app_startup_result.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';

void main() {
  group('AppStartupResult', () {
    test('isSuccess is true only when error is null', () {
      const result = AppStartupResult(
        buildInfo: AppBuildInfo(version: '1.0.0', buildNumber: '1'),
        settingsLoaded: true,
        localeApplied: true,
      );
      expect(result.isSuccess, isTrue);

      const failed = AppStartupResult(
        buildInfo: AppBuildInfo(version: '1.0.0', buildNumber: '1'),
        settingsLoaded: false,
        localeApplied: false,
        error: AppStartupError(diagnosticId: 'STARTUP-UNKNOWN'),
      );
      expect(failed.isSuccess, isFalse);
    });

    test('copyWith replaces only the provided fields', () {
      const original = AppStartupResult(
        buildInfo: AppBuildInfo(version: '1.0.0', buildNumber: '1'),
        settingsLoaded: true,
        localeApplied: true,
      );
      const error = AppStartupError(diagnosticId: 'STARTUP-CONFIG');
      final updated = original.copyWith(settingsLoaded: false, error: error);

      expect(updated.buildInfo, original.buildInfo);
      expect(updated.settingsLoaded, isFalse);
      expect(updated.localeApplied, isTrue);
      expect(updated.error, error);
      expect(original.error, isNull);
    });

    test('equality compares build info fields and flags', () {
      const a = AppStartupResult(
        buildInfo: AppBuildInfo(version: '1.0.0', buildNumber: '1'),
        settingsLoaded: true,
        localeApplied: true,
      );
      const b = AppStartupResult(
        buildInfo: AppBuildInfo(version: '1.0.0', buildNumber: '1'),
        settingsLoaded: true,
        localeApplied: true,
      );
      const c = AppStartupResult(
        buildInfo: AppBuildInfo(version: '2.0.0', buildNumber: '1'),
        settingsLoaded: true,
        localeApplied: true,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
    });
  });

  group('AppStartupError', () {
    test('equality compares diagnostic id and message', () {
      const a = AppStartupError(diagnosticId: 'STARTUP-UNKNOWN', message: 'boom');
      const b = AppStartupError(diagnosticId: 'STARTUP-UNKNOWN', message: 'boom');
      const c = AppStartupError(diagnosticId: 'STARTUP-CONFIG');

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
    });
  });
}
