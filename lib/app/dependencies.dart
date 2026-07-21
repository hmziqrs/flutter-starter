import 'package:starter/features/settings/in_memory_settings_store.dart';
import 'package:starter/features/settings/settings_repository.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/infrastructure/logging/app_logger.dart';
import 'package:starter/infrastructure/preferences/shared_preferences_settings_store.dart';

final class AppDependencies {
  const AppDependencies({
    required this.settingsRepository,
    required this.initialSettings,
  });

  factory AppDependencies.inMemory({
    SettingsState initialSettings = const SettingsState.defaults(),
  }) {
    return AppDependencies(
      settingsRepository: SettingsRepository(InMemorySettingsStore()),
      initialSettings: initialSettings,
    );
  }

  final SettingsRepository settingsRepository;
  final SettingsState initialSettings;

  static Future<AppDependencies> production(AppLogger logger) async {
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
    );
  }
}
