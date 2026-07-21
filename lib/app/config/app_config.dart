import 'package:starter/app/config/app_environment.dart';

final class AppConfig {
  factory AppConfig({
    required AppEnvironment environment,
    required bool enableVerboseLogging,
    required bool enableDevTools,
  }) {
    if (environment == AppEnvironment.production && (enableVerboseLogging || enableDevTools)) {
      throw const AppConfigException(
        'Production cannot enable verbose logging or development tools.',
      );
    }

    return AppConfig._(
      environment: environment,
      enableVerboseLogging: enableVerboseLogging,
      enableDevTools: enableDevTools,
    );
  }

  const AppConfig._({
    required this.environment,
    required this.enableVerboseLogging,
    required this.enableDevTools,
  });

  factory AppConfig.fromEnvironment() {
    return AppConfig.fromValues(
      appEnvironment: const String.fromEnvironment('APP_ENV'),
      enableVerboseLogging: const String.fromEnvironment('ENABLE_VERBOSE_LOGGING'),
      enableDevTools: const String.fromEnvironment('ENABLE_DEV_TOOLS'),
    );
  }

  factory AppConfig.fromValues({
    required String appEnvironment,
    required String enableVerboseLogging,
    required String enableDevTools,
  }) {
    return AppConfig(
      environment: AppEnvironment.parse(appEnvironment),
      enableVerboseLogging: _parseBoolean(
        key: 'ENABLE_VERBOSE_LOGGING',
        value: enableVerboseLogging,
      ),
      enableDevTools: _parseBoolean(
        key: 'ENABLE_DEV_TOOLS',
        value: enableDevTools,
      ),
    );
  }

  final AppEnvironment environment;
  final bool enableVerboseLogging;
  final bool enableDevTools;

  bool get verboseLoggingEnabled =>
      environment == AppEnvironment.development && enableVerboseLogging;

  bool get developmentToolsEnabled => environment == AppEnvironment.development && enableDevTools;

  static bool _parseBoolean({required String key, required String value}) {
    return switch (value.trim().toLowerCase()) {
      'true' => true,
      'false' => false,
      _ => throw AppConfigException('$key must be either "true" or "false".'),
    };
  }
}

final class AppConfigException implements Exception {
  const AppConfigException(this.message);

  final String message;

  @override
  String toString() => 'AppConfigException: $message';
}
