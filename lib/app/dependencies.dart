import 'package:starter/features/announcements/announcements_controller.dart';
import 'package:starter/features/auth/auth_attempt_tracker.dart';
import 'package:starter/features/feature_flags/feature_flags.dart';
import 'package:starter/features/feature_flags/feature_flags_source.dart';
import 'package:starter/features/feature_flags/in_memory_feature_flags_source.dart';
import 'package:starter/features/force_update/in_memory_version_gate_store.dart';
import 'package:starter/features/force_update/update_requirement.dart';
import 'package:starter/features/force_update/version_gate_store.dart';
import 'package:starter/features/security/in_memory_secure_store.dart';
import 'package:starter/features/session/auth_repository.dart';
import 'package:starter/features/session/auth_session.dart';
import 'package:starter/features/session/in_memory_auth_repository.dart';
import 'package:starter/features/session/session_repository.dart';
import 'package:starter/features/settings/in_memory_settings_store.dart';
import 'package:starter/features/settings/settings_repository.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/features/settings/settings_store.dart';
import 'package:starter/features/splash/app_startup_result.dart';
import 'package:starter/infrastructure/analytics/analytics_client.dart';
import 'package:starter/infrastructure/analytics/noop_analytics_client.dart';
import 'package:starter/infrastructure/biometric/biometric_authenticator.dart';
import 'package:starter/infrastructure/biometric/local_auth_authenticator.dart';
import 'package:starter/infrastructure/biometric/noop_biometric_authenticator.dart';
import 'package:starter/infrastructure/connectivity/connectivity_plus_service.dart';
import 'package:starter/infrastructure/connectivity/connectivity_service.dart';
import 'package:starter/infrastructure/error_reporting/crash_reporter.dart';
import 'package:starter/infrastructure/error_reporting/noop_crash_reporter.dart';
import 'package:starter/infrastructure/logging/app_logger.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';
import 'package:starter/infrastructure/platform/platform_capabilities.dart';
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
    required this.appStartupResult,
    required this.buildInfo,
    required this.initialDismissedAnnouncementIds,
    required this.authRepository,
    required this.sessionRepository,
    required this.initialSession,
    required this.analyticsClient,
    required this.analyticsClientBackend,
    required this.initialAnalyticsOptIn,
    required this.featureFlagsSource,
    required this.biometricAuthenticator,
    required this.attemptTracker,
  });

  factory AppDependencies.inMemory({
    SettingsState? initialSettings,
    SecureStore? secureStore,
    AuthSession? initialSession,
  }) {
    final settingsStore = InMemorySettingsStore();
    // No-backend default: the in-memory version gate always returns none, so
    // the redirect never short-circuits in tests (C2: never fake a block).
    final versionGateStore = InMemoryVersionGateStore();
    final effectiveSecureStore = secureStore ?? InMemorySecureStore();
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
      secureStore: effectiveSecureStore,
      crashReporter: const NoopCrashReporter(),
      crashReporterBackend: const NoopCrashReporterBackend(),
      versionGateStore: versionGateStore,
      versionCheck: const UpdateRequirementNone(),
      // Backend-free per spec: the real local connectivity_plus sensor IS the
      // production default (no Noop, no credentials). Safe in integration tests
      // on a real platform; widget tests override connectivityServiceProvider.
      connectivityService: ConnectivityPlusService(),
      // Splash seed: a resolved success so test harnesses that read the
      // startup result never throw (mirrors the inMemory
      // hasCompletedOnboarding:true default). The test build info mirrors the
      // global test fixture in app_build_info_test.dart.
      appStartupResult: const AppStartupResult(
        buildInfo: AppBuildInfo(version: '0.0.0', buildNumber: '0'),
        settingsLoaded: true,
        localeApplied: true,
      ),
      buildInfo: const AppBuildInfo(version: '1.0.0', buildNumber: '1'),
      // No dismissed announcements in the test harness — the default feed
      // surfaces its first fixture.
      initialDismissedAnnouncementIds: const <String>{},
      // Wave-4 ports. All no-backend defaults so tests never trigger a real
      // adapter (C2): the unseeded InMemoryAuthRepository surfaces notConnected
      // rather than faking a session, NoopAnalyticsClient routes through the
      // logger, InMemoryFeatureFlagsSource returns defaults, the Noop biometric
      // authenticator reports canCheck:false honestly, and the in-memory
      // attempt tracker is fresh per launch.
      authRepository: InMemoryAuthRepository(),
      sessionRepository: SessionRepository(effectiveSecureStore),
      initialSession: initialSession ?? const AuthAnonymous(),
      analyticsClient: NoopAnalyticsClient(logger: AppLogger.bootstrap()),
      analyticsClientBackend: const NoopAnalyticsBackend(),
      initialAnalyticsOptIn: false,
      featureFlagsSource: InMemoryFeatureFlagsSource(),
      biometricAuthenticator: const NoopBiometricAuthenticator(),
      attemptTracker: InMemoryAttemptTracker(),
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

  /// Typed summary of the work `createApplication` already performs (build-info
  /// load, settings load, locale apply). Carried out of the composition root so
  /// SplashPage can observe the existing init future without re-running any of
  /// it. Built in `AppDependencies.production` from the load outcome and the
  /// already-loaded build info; `localeApplied` is finalized in
  /// `createApplication` once the locale apply runs (see copyWith below).
  final AppStartupResult appStartupResult;

  /// The installed build, surfaced for the announcements version window. Reuses
  /// the value already loaded for the update check rather than reading
  /// `PackageInfo` a second time.
  final AppBuildInfo? buildInfo;

  /// Cold-start seed of dismissed announcement ids (decoded from the
  /// `announcements.dismissedIds` settings key). Mirrors `initialSettings`:
  /// pre-loaded at the composition root so the controller resolves synchronously.
  final Set<String> initialDismissedAnnouncementIds;

  /// Session auth port + refresh-token repository + cold-start session seed.
  /// The honest no-backend default is unseeded [InMemoryAuthRepository] +
  /// [AuthAnonymous] (C2: a cold start never fakes a session). The consumer
  /// swaps in a real HTTP adapter against the test-server contract when an
  /// endpoint is configured.
  final AuthRepository authRepository;
  final SessionRepository sessionRepository;
  final AuthSession initialSession;

  /// Analytics port + read-only backend descriptor + cold-start opt-in seed.
  /// The no-backend default is [NoopAnalyticsClient] (routes through AppLogger
  /// and never fakes a success state). The opt-in seed is pre-loaded from
  /// SecureStore so the controller resolves synchronously on the first frame.
  final AnalyticsClient analyticsClient;
  final AnalyticsClientBackend analyticsClientBackend;
  final bool initialAnalyticsOptIn;

  /// Feature-flags source. The no-backend default returns [FeatureFlags.defaults]
  /// and emits nothing; a remote-config backend is a consumer override only.
  final FeatureFlagsSource featureFlagsSource;

  /// Biometric authenticator. Selected from `PlatformCapabilities` at the
  /// composition root: real [LocalAuthAuthenticator] on supported native
  /// platforms, honest [NoopBiometricAuthenticator] for web/unsupported.
  final BiometricAuthenticator biometricAuthenticator;

  /// Local per-identifier attempt/lockout tracker (UX-only, pure-Dart). Fresh
  /// per launch; shared by login, OTP, and the future pin-autolock surface.
  final AttemptTracker attemptTracker;

  /// Returns a copy with the provided fields replaced. Used by
  /// `createApplication` to finalize the startup result's `localeApplied` flag
  /// once the locale apply has run (which happens after `AppDependencies.production`).
  AppDependencies copyWith({AppStartupResult? appStartupResult}) {
    return AppDependencies(
      settingsRepository: settingsRepository,
      settingsStore: settingsStore,
      initialSettings: initialSettings,
      secureStore: secureStore,
      crashReporter: crashReporter,
      crashReporterBackend: crashReporterBackend,
      versionGateStore: versionGateStore,
      versionCheck: versionCheck,
      connectivityService: connectivityService,
      appStartupResult: appStartupResult ?? this.appStartupResult,
      buildInfo: buildInfo,
      initialDismissedAnnouncementIds: initialDismissedAnnouncementIds,
      authRepository: authRepository,
      sessionRepository: sessionRepository,
      initialSession: initialSession,
      analyticsClient: analyticsClient,
      analyticsClientBackend: analyticsClientBackend,
      initialAnalyticsOptIn: initialAnalyticsOptIn,
      featureFlagsSource: featureFlagsSource,
      biometricAuthenticator: biometricAuthenticator,
      attemptTracker: attemptTracker,
    );
  }

  static Future<AppDependencies> production(
    AppLogger logger, {
    AppBuildInfo? buildInfo,
  }) async {
    final settingsStore = SharedPreferencesSettingsStore();
    final repository = SettingsRepository(settingsStore);
    SettingsState settings;
    var settingsLoaded = true;
    try {
      settings = await repository.load();
    } on SettingsFailure catch (error, stackTrace) {
      logger.error(
        'Unable to load settings; using safe defaults',
        error: error,
        stackTrace: stackTrace,
      );
      settings = const SettingsState.defaults();
      settingsLoaded = false;
    }
    // Pre-load the dismissed-announcement id set so AnnouncementsController
    // resolves active synchronously on the first frame. Tolerant of malformed
    // storage (treated as "nothing dismissed" rather than throwing).
    final initialDismissedAnnouncementIds = DismissedAnnouncements.decode(
      await settingsStore.readString(DismissedAnnouncements.key),
    );
    // No-backend default: InMemoryVersionGateStore returns none, so production
    // runs green with zero backend wiring (C2). The optional
    // RemoteConfigVersionGateStore activates only when a remote-config backend
    // is configured; until that wiring lands, the honest none default is used.
    final versionGateStore = InMemoryVersionGateStore();
    final versionCheck = buildInfo == null
        ? const UpdateRequirementNone()
        : await versionGateStore.check(buildInfo);
    // Shared SecureStore reused by the session repository and the analytics
    // opt-in pre-load so the keychain is opened once.
    final secureStore = FlutterSecureStorageStore();
    // Pre-load the analytics opt-in flag (a single SecureStore read) so the
    // AnalyticsOptInController resolves synchronously on the first frame. A
    // keychain failure degrades to "not opted in" rather than throwing
    // (guardrail 13: never risk an unexpected emit).
    var initialAnalyticsOptIn = false;
    try {
      initialAnalyticsOptIn = await secureStore.read(analyticsOptInKey) == 'true';
    } on Object {
      initialAnalyticsOptIn = false;
    }
    // Select the biometric authenticator from the current platform: real
    // local_auth on supported native platforms, honest Noop for web/unsupported
    // (the Noop reports canCheck:false and never fakes a success).
    final capabilities = PlatformCapabilities.current();
    final biometricAuthenticator = capabilities.isWeb
        ? const NoopBiometricAuthenticator()
        : LocalAuthAuthenticator();
    return AppDependencies(
      settingsRepository: repository,
      settingsStore: settingsStore,
      initialSettings: settings,
      secureStore: secureStore,
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
      // Forward the startup signals WITHOUT re-loading: buildInfo and
      // settingsLoaded are already known here. `localeApplied` is set true
      // optimistically because the locale apply runs in `createApplication`
      // after this factory returns; `createApplication` finalizes it via
      // copyWith when the apply fails.
      appStartupResult: AppStartupResult(
        buildInfo: buildInfo ?? const AppBuildInfo(version: '0.0.0', buildNumber: '0'),
        settingsLoaded: settingsLoaded,
        localeApplied: true,
      ),
      buildInfo: buildInfo,
      initialDismissedAnnouncementIds: initialDismissedAnnouncementIds,
      // Wave-4 no-backend production defaults. Each is an override seam the
      // consumer activates only when credentials/an endpoint are configured;
      // every default degrades honestly and never fakes success (C2).
      authRepository: InMemoryAuthRepository(),
      sessionRepository: SessionRepository(secureStore),
      initialSession: const AuthAnonymous(),
      analyticsClient: NoopAnalyticsClient(logger: logger),
      analyticsClientBackend: const NoopAnalyticsBackend(),
      initialAnalyticsOptIn: initialAnalyticsOptIn,
      featureFlagsSource: InMemoryFeatureFlagsSource(),
      biometricAuthenticator: biometricAuthenticator,
      attemptTracker: InMemoryAttemptTracker(),
    );
  }
}
