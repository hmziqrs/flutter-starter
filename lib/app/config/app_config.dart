import 'package:starter/app/config/app_environment.dart';
import 'package:starter/app/routing/app_link_handler.dart';

final class AppConfig {
  factory AppConfig({
    required AppEnvironment environment,
    required bool enableVerboseLogging,
    required bool enableDevTools,
    required String iosAppleId,
    required AllowedDeepLinkHosts allowedDeepLinkHosts,
    Uri? backendBaseUrl,
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
      iosAppleId: iosAppleId,
      allowedDeepLinkHosts: allowedDeepLinkHosts,
      backendBaseUrl: backendBaseUrl,
    );
  }

  const AppConfig._({
    required this.environment,
    required this.enableVerboseLogging,
    required this.enableDevTools,
    required this.iosAppleId,
    required this.allowedDeepLinkHosts,
    required this.backendBaseUrl,
  });

  factory AppConfig.fromEnvironment() {
    return AppConfig.fromValues(
      appEnvironment: const String.fromEnvironment('APP_ENV'),
      enableVerboseLogging: const String.fromEnvironment('ENABLE_VERBOSE_LOGGING'),
      enableDevTools: const String.fromEnvironment('ENABLE_DEV_TOOLS'),
      iosAppleId: const String.fromEnvironment('IOS_APPLE_ID'),
      allowedDeepLinkHosts: AllowedDeepLinkHosts.parse(
        const String.fromEnvironment('ALLOWED_DEEP_LINK_HOSTS'),
      ),
      backendBaseUrl: const String.fromEnvironment('BACKEND_BASE_URL'),
    );
  }

  factory AppConfig.fromValues({
    required String appEnvironment,
    required String enableVerboseLogging,
    required String enableDevTools,
    required String iosAppleId,
    required AllowedDeepLinkHosts allowedDeepLinkHosts,
    required String backendBaseUrl,
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
      backendBaseUrl: _parseBackendBaseUrl(backendBaseUrl),
      iosAppleId: iosAppleId.trim(),
      allowedDeepLinkHosts: allowedDeepLinkHosts,
    );
  }

  final AppEnvironment environment;
  final bool enableVerboseLogging;
  final bool enableDevTools;

  /// Builds the App Store deep-link for in-app-update on iOS. Empty when
  /// unconfigured; the update adapter degrades honestly to a no-op launch.
  final String iosAppleId;

  /// Compile-time allowlist of hosts accepted for inbound deep-link URIs.
  /// Empty resolves every inbound URI to `null`.
  final AllowedDeepLinkHosts allowedDeepLinkHosts;

  /// Base URL of the optional backend used for auth/OTP/register/profile
  /// integration tests. `null` keeps the no-backend composition (InMemory
  /// adapters degrade to `notConnected`); non-null wires the HTTP adapters.
  final Uri? backendBaseUrl;

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

  static Uri? _parseBackendBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    try {
      return Uri.parse(trimmed);
    } on FormatException {
      throw const AppConfigException('BACKEND_BASE_URL must be a valid URI or empty.');
    }
  }
}

final class AppConfigException implements Exception {
  const AppConfigException(this.message);

  final String message;

  @override
  String toString() => 'AppConfigException: $message';
}
