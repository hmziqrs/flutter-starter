import 'package:starter/features/security/in_memory_secure_store.dart';
import 'package:starter/features/settings/in_memory_settings_store.dart';
import 'package:starter/features/settings/settings_repository.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/infrastructure/error_reporting/crash_reporter.dart';
import 'package:starter/infrastructure/error_reporting/noop_crash_reporter.dart';
import 'package:starter/infrastructure/logging/app_logger.dart';
import 'package:starter/infrastructure/preferences/shared_preferences_settings_store.dart';
import 'package:starter/infrastructure/secure_storage/flutter_secure_storage_store.dart';
import 'package:starter/infrastructure/secure_storage/secure_store.dart';

final class AppDependencies {
  const AppDependencies({
    required this.settingsRepository,
    required this.initialSettings,
    required this.secureStore,
    required this.crashReporter,
    required this.crashReporterBackend,
  });

  factory AppDependencies.inMemory({
    SettingsState initialSettings = const SettingsState.defaults(),
    SecureStore? secureStore,
  }) {
    return AppDependencies(
      settingsRepository: SettingsRepository(InMemorySettingsStore()),
      initialSettings: initialSettings,
      secureStore: secureStore ?? InMemorySecureStore(),
      crashReporter: const NoopCrashReporter(),
      crashReporterBackend: const NoopCrashReporterBackend(),
    );
  }

  final SettingsRepository settingsRepository;
  final SettingsState initialSettings;
  final SecureStore secureStore;
  final CrashReporter crashReporter;
  final CrashReporterBackend crashReporterBackend;

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
      secureStore: FlutterSecureStorageStore(),
      // No-backend defaults. The optional remote SentryCrashReporter branch
      // activates only when a crash-reporting DSN is configured; until that
      // wiring lands, the app runs green with an honest no-op sink (C2).
      crashReporter: const NoopCrashReporter(),
      crashReporterBackend: const NoopCrashReporterBackend(),
    );
  }
}
