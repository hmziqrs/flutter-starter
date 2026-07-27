import 'package:flutter/foundation.dart';
import 'package:starter/features/settings/in_memory_settings_store.dart';
import 'package:starter/features/settings/settings_repository.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/infrastructure/logging/app_logger.dart';
import 'package:starter/infrastructure/platform/platform_capabilities.dart';
import 'package:starter/infrastructure/platform/platform_capabilities_resolver.dart';
import 'package:starter/infrastructure/preferences/shared_preferences_settings_store.dart';

final class AppDependencies {
  const AppDependencies({
    required this.settingsRepository,
    required this.initialSettings,
    required this.platformCapabilities,
  });

  factory AppDependencies.inMemory({
    SettingsState initialSettings = const SettingsState.defaults(),
    PlatformCapabilities platformCapabilities = const PlatformCapabilities.nonTelevision(),
  }) {
    return AppDependencies(
      settingsRepository: SettingsRepository(InMemorySettingsStore()),
      initialSettings: initialSettings,
      platformCapabilities: platformCapabilities,
    );
  }

  final SettingsRepository settingsRepository;
  final SettingsState initialSettings;
  final PlatformCapabilities platformCapabilities;

  static Future<AppDependencies> production(
    AppLogger logger, {
    PlatformCapabilitiesResolver capabilitiesResolver = const PlatformCapabilitiesResolver(),
  }) async {
    PlatformCapabilities capabilities;
    try {
      capabilities = await capabilitiesResolver.resolve();
    } on Object catch (error) {
      logger.warning(
        'Unable to resolve optional platform capabilities; using non-TV defaults',
        context: <String, Object?>{'errorType': error.runtimeType.toString()},
      );
      capabilities = PlatformCapabilities(
        platform: defaultTargetPlatform.name,
        isWeb: kIsWeb,
        tvPlatform: AppTvPlatform.none,
      );
    }

    final repository = SettingsRepository(SharedPreferencesSettingsStore());
    SettingsState settings;
    try {
      settings = await repository.load();
    } on SettingsFailure catch (error, stackTrace) {
      logger.error(
        'Unable to load settings; using safe defaults',
        error: error,
        stackTrace: stackTrace,
      );
      settings = const SettingsState.defaults();
    }
    return AppDependencies(
      settingsRepository: repository,
      initialSettings: settings,
      platformCapabilities: capabilities,
    );
  }
}
