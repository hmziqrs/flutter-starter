import 'package:flutter_test/flutter_test.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/config/app_environment.dart';

void main() {
  group('AppEnvironment', () {
    test('parses every supported value', () {
      expect(AppEnvironment.parse('development'), AppEnvironment.development);
      expect(AppEnvironment.parse('STAGING'), AppEnvironment.staging);
      expect(AppEnvironment.parse(' production '), AppEnvironment.production);
    });

    test('rejects a missing value', () {
      expect(
        () => AppEnvironment.parse(''),
        throwsA(isA<AppEnvironmentException>()),
      );
    });

    test('rejects an unknown value', () {
      expect(
        () => AppEnvironment.parse('preview'),
        throwsA(isA<AppEnvironmentException>()),
      );
    });
  });

  group('AppConfig', () {
    test('parses explicit development values', () {
      final config = AppConfig.fromValues(
        appEnvironment: 'development',
        enableVerboseLogging: 'true',
        enableDevTools: 'true',
      );

      expect(config.environment, AppEnvironment.development);
      expect(config.verboseLoggingEnabled, isTrue);
      expect(config.developmentToolsEnabled, isTrue);
    });

    test('keeps development flags ineffective outside development', () {
      final config = AppConfig.fromValues(
        appEnvironment: 'staging',
        enableVerboseLogging: 'true',
        enableDevTools: 'true',
      );

      expect(config.enableVerboseLogging, isTrue);
      expect(config.enableDevTools, isTrue);
      expect(config.verboseLoggingEnabled, isFalse);
      expect(config.developmentToolsEnabled, isFalse);
    });

    test('rejects an invalid boolean', () {
      expect(
        () => AppConfig.fromValues(
          appEnvironment: 'development',
          enableVerboseLogging: 'yes',
          enableDevTools: 'true',
        ),
        throwsA(isA<AppConfigException>()),
      );
    });

    test('rejects unsafe production flags', () {
      expect(
        () => AppConfig.fromValues(
          appEnvironment: 'production',
          enableVerboseLogging: 'false',
          enableDevTools: 'true',
        ),
        throwsA(isA<AppConfigException>()),
      );
    });
  });
}
