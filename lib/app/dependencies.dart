import 'package:starter/features/force_update/in_memory_version_gate_store.dart';
import 'package:starter/features/force_update/update_requirement.dart';
import 'package:starter/features/force_update/version_gate_store.dart';
import 'package:starter/features/security/in_memory_secure_store.dart';
import 'package:starter/features/settings/in_memory_settings_store.dart';
import 'package:starter/features/settings/settings_repository.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/features/settings/settings_store.dart';
import 'package:starter/infrastructure/connectivity/connectivity_plus_service.dart';
import 'package:starter/infrastructure/connectivity/connectivity_service.dart';
import 'package:starter/infrastructure/error_reporting/crash_reporter.dart';
import 'package:starter/infrastructure/error_reporting/noop_crash_reporter.dart';
import 'package:starter/infrastructure/logging/app_logger.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';
import 'package:starter/infrastructure/preferences/shared_preferences_settings_store.dart';
import 'package:starter/infrastructure/secure_storage/flutter_secure_storage_store.dart';
import 'package:starter/infrastructure/secure_storage/secure_store.dart';

final class AppDependencies {
  const AppDependencies({
    required this.settingsRepository,
    required this.settingsStore,
    required this.initialSettings,
    required this.secureStore,
    required this.crashReporter,
    required this.crashReporterBackend,
    required this.versionGateStore,
    required this.versionCheck,
    required this.connectivityService,
  });

  factory AppDependencies.inMemory({
    SettingsState? initialSettings,
    SecureStore? secureStore,
  }) {
    final settingsStore = InMemorySettingsStore();
    // No-backend default: the in-memory version gate always returns none, so
    // the redirect never short-circuits in tests (C2: never fake a block).
    final versionGateStore = InMemoryVersionGateStore();
    return AppDependencies(
      settingsRepository: SettingsRepository(settingsStore),
      settingsStore: settingsStore,
      // Test default: a returning user who has completed onboarding, so the
      // shell / navigation / gallery suites boot straight to home. The
      // fresh-install onboarding-redirect contract is covered independently by
      // app_router_onboarding_redirect_test.dart, which builds its own
      // fresh-install dependencies rather than relying on this factory.
      initialSettings:
          initialSettings ?? const SettingsState.defaults().copyWith(hasCompletedOnboarding: true),
      secureStore: secureStore ?? InMemorySecureStore(),
      crashReporter: const NoopCrashReporter(),
      crashReporterBackend: const NoopCrashReporterBackend(),
      versionGateStore: versionGateStore,
      versionCheck: const UpdateRequirementNone(),
      // Backend-free per spec: the real local connectivity_plus sensor IS the
      // production default (no Noop, no credentials). Safe in integration tests
      // on a real platform; widget tests override connectivityServiceProvider.
      connectivityService: ConnectivityPlusService(),
    );
  }

  final SettingsRepository settingsRepository;
  final SettingsStore settingsStore;
  final SettingsState initialSettings;
  final SecureStore secureStore;
  final CrashReporter crashReporter;
  final CrashReporterBackend crashReporterBackend;
  final VersionGateStore versionGateStore;
  final UpdateRequirement versionCheck;
  final ConnectivityService connectivityService;

  static Future<AppDependencies> production(
    AppLogger logger, {
    AppBuildInfo? buildInfo,
  }) async {
    final settingsStore = SharedPreferencesSettingsStore();
    final repository = SettingsRepository(settingsStore);
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
    // No-backend default: InMemoryVersionGateStore returns none, so production
    // runs green with zero backend wiring (C2). The optional
    // RemoteConfigVersionGateStore activates only when a remote-config backend
    // is configured; until that wiring lands, the honest none default is used.
    final versionGateStore = InMemoryVersionGateStore();
    final versionCheck = buildInfo == null
        ? const UpdateRequirementNone()
        : await versionGateStore.check(buildInfo);
    return AppDependencies(
      settingsRepository: repository,
      settingsStore: settingsStore,
      initialSettings: settings,
      secureStore: FlutterSecureStorageStore(),
      // No-backend defaults. The optional remote SentryCrashReporter branch
      // activates only when a crash-reporting DSN is configured; until that
      // wiring lands, the app runs green with an honest no-op sink (C2).
      crashReporter: const NoopCrashReporter(),
      crashReporterBackend: const NoopCrashReporterBackend(),
      versionGateStore: versionGateStore,
      versionCheck: versionCheck,
      // Backend-free per spec: the real local connectivity_plus sensor IS the
      // production default (no Noop, no credentials). A sensor failure degrades
      // honestly to offline and never fakes online.
      connectivityService: ConnectivityPlusService(),
    );
  }
}
