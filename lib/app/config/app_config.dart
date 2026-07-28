import 'package:starter/app/config/app_environment.dart';
import 'package:starter/app/routing/app_link_handler.dart';

final class AppConfig {
  factory AppConfig({
    required AppEnvironment environment,
    required bool enableVerboseLogging,
    required bool enableDevTools,
    required String iosAppleId,
    required AllowedDeepLinkHosts allowedDeepLinkHosts,
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
    );
  }

  const AppConfig._({
    required this.environment,
    required this.enableVerboseLogging,
    required this.enableDevTools,
    required this.iosAppleId,
    required this.allowedDeepLinkHosts,
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
    );
  }

  factory AppConfig.fromValues({
    required String appEnvironment,
    required String enableVerboseLogging,
    required String enableDevTools,
    required String iosAppleId,
    required AllowedDeepLinkHosts allowedDeepLinkHosts,
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
      // iOS App Store Apple ID and the deep-link host allowlist are
      // compile-time `--dart-define-from-file` values (NOT secrets — the Apple
      // ID is public and ships in the binary either way; the host allowlist is
      // a public security boundary). Empty defaults disable the in-app-update
      // iOS store link and inbound deep-link routing respectively (the honest
      // no-backend default).
      iosAppleId: iosAppleId.trim(),
      allowedDeepLinkHosts: allowedDeepLinkHosts,
    );
  }

  final AppEnvironment environment;
  final bool enableVerboseLogging;
  final bool enableDevTools;

  /// The iOS App Store Apple ID used to build the App Store deep-link for the
  /// in-app-update iOS path (`itms-apps://itunes.apple.com/app/id<ID>`). Empty
  /// when not configured (compile-time `IOS_APPLE_ID` define); the iOS update
  /// adapter degrades honestly to a no-op launch.
  final String iosAppleId;

  /// Compile-time allowlist of hosts the app will accept inbound deep-link URIs
  /// from (the security boundary for the deep-linking receiver). Empty by
  /// default — inbound deep-link routing resolves every URI to `null` until a
  /// consumer configures `ALLOWED_DEEP_LINK_HOSTS`.
  final AllowedDeepLinkHosts allowedDeepLinkHosts;

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
