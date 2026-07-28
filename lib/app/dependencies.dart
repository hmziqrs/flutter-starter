import 'package:starter/app/routing/app_link_handler.dart';
import 'package:starter/features/announcements/announcements_controller.dart';
import 'package:starter/features/auth/auth_attempt_tracker.dart';
import 'package:starter/features/auth/in_memory_otp_repository.dart';
import 'package:starter/features/auth/otp_repository.dart';
import 'package:starter/features/feature_flags/feature_flags.dart';
import 'package:starter/features/feature_flags/feature_flags_source.dart';
import 'package:starter/features/feature_flags/in_memory_feature_flags_source.dart';
import 'package:starter/features/force_update/in_memory_version_gate_store.dart';
import 'package:starter/features/force_update/update_requirement.dart';
import 'package:starter/features/force_update/version_gate_store.dart';
import 'package:starter/features/notifications/noop_notifications_repository.dart';
import 'package:starter/features/notifications/notification_permission_status.dart';
import 'package:starter/features/notifications/notifications_repository.dart';
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
import 'package:starter/infrastructure/haptics/device_haptic_service.dart';
import 'package:starter/infrastructure/haptics/haptic_service.dart';
import 'package:starter/infrastructure/haptics/noop_haptic_service.dart';
import 'package:starter/infrastructure/logging/app_logger.dart';
import 'package:starter/infrastructure/media/image_picker_media_picker.dart';
import 'package:starter/infrastructure/media/media_picker.dart';
import 'package:starter/infrastructure/media/noop_media_picker.dart';
import 'package:starter/infrastructure/permissions/device_permission_service.dart';
import 'package:starter/infrastructure/permissions/noop_permission_service.dart';
import 'package:starter/infrastructure/permissions/permission_service.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';
import 'package:starter/infrastructure/platform/platform_capabilities.dart';
import 'package:starter/infrastructure/preferences/shared_preferences_settings_store.dart';
import 'package:starter/infrastructure/secure_storage/flutter_secure_storage_store.dart';
import 'package:starter/infrastructure/secure_storage/secure_store.dart';
import 'package:starter/infrastructure/sharing/noop_share_service.dart';
import 'package:starter/infrastructure/sharing/share_plus_share_service.dart';
import 'package:starter/infrastructure/sharing/share_service.dart';
import 'package:starter/infrastructure/updates/android_app_update_service.dart';
import 'package:starter/infrastructure/updates/app_update_service.dart';
import 'package:starter/infrastructure/updates/ios_app_update_service.dart';
import 'package:starter/infrastructure/updates/noop_app_update_service.dart';

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
    required this.hapticService,
    required this.otpRepository,
    required this.notificationsRepository,
    required this.notificationsBackend,
    required this.initialNotificationPermission,
    required this.initialNotificationToken,
    required this.permissionService,
    required this.mediaPicker,
    required this.shareService,
    required this.appUpdateService,
    required this.appLinkHandler,
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
      // Haptics: Noop keeps hermeticity so a tap in a test/golden harness never
      // reaches the platform channel.
      hapticService: NoopHapticService(),
      // Wave-5b ports. Honest no-backend defaults so tests/goldens never reach
      // a real platform channel (C2 / C13): InMemoryOtpRepository surfaces
      // notConnected, NoopNotificationsRepository reports denied, the Noop
      // permission/media/share/update adapters report denied / null /
      // unavailable / noUpdate honestly. The real platform adapters are
      // selected by `AppDependencies.production` per PlatformCapabilities.
      otpRepository: const InMemoryOtpRepository(),
      notificationsRepository: const NoopNotificationsRepository(),
      notificationsBackend: const NoopNotificationsBackend(),
      initialNotificationPermission: NotificationPermissionStatus.notRequested,
      initialNotificationToken: null,
      permissionService: const NoopPermissionService(),
      mediaPicker: const NoopMediaPicker(),
      shareService: const NoopShareService(),
      appUpdateService: const NoopAppUpdateService(),
      // Deep-link handler: tests do not drive inbound URIs; pass a no-op
      // service whose stream is empty and whose initial link is null. A test
      // that needs to drive links overrides the provider directly.
      appLinkHandler: const _NoOpDeepLinkService(),
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

  /// Haptic feedback port. The local device IS the production backend
  /// ([DeviceHapticService] wraps `flutter/services` `HapticFeedback` — no
  /// credentials, no faking, C2); [NoopHapticService] is the hermeticity-only
  /// default for tests/goldens. Each call site additionally gates on
  /// `MediaQuery.disableAnimationsOf` and the `hapticsEnabled` setting.
  final HapticService hapticService;

  /// OTP repository port (mfa-otp). The no-backend default
  /// ([InMemoryOtpRepository]) surfaces `OtpRepositoryException.notConnected`
  /// and never fakes an issued code; the optional real HTTP adapter against
  /// the `tools/test_server/` OTP contract is a consumer override only.
  final OtpRepository otpRepository;

  /// Push notifications port (push-notifications). The no-backend default
  /// ([NoopNotificationsRepository]) reports denied, publishes empty streams,
  /// and throws notConnected for the registration actions. The optional real
  /// Firebase adapter is constructed by the consumer only when credentials are
  /// wired AND the platform is iOS / Android.
  final NotificationsRepository notificationsRepository;
  final NotificationsBackend notificationsBackend;
  final NotificationPermissionStatus initialNotificationPermission;
  final String? initialNotificationToken;

  /// Runtime-permission port (permissions-media). The composition root selects
  /// `DevicePermissionService` on supported native platforms or the honest
  /// `NoopPermissionService` for web / unsupported / integration-test runs.
  final PermissionService permissionService;

  /// Media-picker port (permissions-media). The composition root selects
  /// `ImagePickerMediaPicker` on supported native platforms or the honest
  /// `NoopMediaPicker` for web / unsupported / integration-test runs.
  final MediaPicker mediaPicker;

  /// Native share-sheet port (license-share-update). The composition root
  /// selects `SharePlusShareService` on platforms with a native share target
  /// or the honest `NoopShareService` for web / unsupported / integration-test
  /// runs.
  final ShareService shareService;

  /// OS-store in-app update port (license-share-update). The composition root
  /// selects `AndroidAppUpdateService` / `IosAppUpdateService` on supported
  /// native platforms or the honest `NoopAppUpdateService` for web /
  /// unsupported / integration-test runs. Non-blocking by design: the server
  /// `VersionGateStore` owns the hard / soft block (no double-block).
  final AppUpdateService appUpdateService;

  /// Inbound deep-link service (deep-linking). Owns the `app_links` plugin
  /// instance and exposes the resolved inbound stream + the cold-start initial
  /// link. Constructed at the composition root with the compile-time
  /// `AllowedDeepLinkHosts`; tests use the no-op service (no inbound URIs).
  final DeepLinkService appLinkHandler;

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
      hapticService: hapticService,
      otpRepository: otpRepository,
      notificationsRepository: notificationsRepository,
      notificationsBackend: notificationsBackend,
      initialNotificationPermission: initialNotificationPermission,
      initialNotificationToken: initialNotificationToken,
      permissionService: permissionService,
      mediaPicker: mediaPicker,
      shareService: shareService,
      appUpdateService: appUpdateService,
      appLinkHandler: appLinkHandler,
    );
  }

  static Future<AppDependencies> production(
    AppLogger logger, {
    required String iosAppleId,
    required AllowedDeepLinkHosts allowedDeepLinkHosts,
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
      // Haptics: the local device IS the production backend (real
      // HapticFeedback — no credentials, no faking, C2). The reduce-motion guard
      // + hapticsEnabled setting are enforced at each call site, not here.
      hapticService: const DeviceHapticService(),
      // Wave-5b no-backend production defaults. Each is a port override seam
      // the consumer activates only when credentials / an endpoint are
      // configured; every default degrades honestly and never fakes success
      // (C2 / C13).
      otpRepository: const InMemoryOtpRepository(),
      // Notifications: Noop is the platform-agnostic default. The optional
      // Firebase adapter is constructed by the consumer only on iOS / Android
      // with credentials (firebase_messaging has no desktop/web support). Web
      // / desktop / no-credentials all stay on the Noop default.
      notificationsRepository: const NoopNotificationsRepository(),
      notificationsBackend: const NoopNotificationsBackend(),
      initialNotificationPermission: NotificationPermissionStatus.notRequested,
      initialNotificationToken: null,
      // Permissions / media / share / update: select the real device adapter on
      // a supported native platform, honest Noop on web / unsupported / test
      // runs. The selection is at the composition root (never via a global);
      // each adapter degrades honestly and never fakes a grant / pick / share /
      // available update.
      permissionService: _selectPermissionService(capabilities),
      mediaPicker: _selectMediaPicker(capabilities),
      shareService: _selectShareService(capabilities),
      appUpdateService: _selectAppUpdateService(capabilities, iosAppleId: iosAppleId),
      // Deep-link handler: the real `app_links` plugin is the production
      // default on mobile; web is handled by `MaterialApp.router`'s browser
      // URL bar (no double-wire); desktop / unsupported degrade honestly (the
      // service publishes nothing, the app boots to its normal initial
      // location). The cold-start `getInitialLink` is captured in
      // `bootstrap.dart` before the router builds.
      appLinkHandler: AppLinksDeepLinkService(
        handler: RouteAppLinkHandler(allowedHosts: allowedDeepLinkHosts),
      ),
    );
  }

  // The platform-selectors below are static private helpers so the production
  // factory stays readable. Each maps a `PlatformCapabilities` snapshot to the
  // honest adapter: real device adapter on supported native platforms, Noop
  // for web / unsupported / integration-test runs. Never a global; never a
  // fabricated success.

  static PermissionService _selectPermissionService(PlatformCapabilities caps) {
    if (caps.isWeb) return const NoopPermissionService();
    return switch (caps.platform) {
      // `permission_handler` is supported on iOS / Android only.
      'ios' || 'android' => DevicePermissionService(),
      _ => const NoopPermissionService(),
    };
  }

  static MediaPicker _selectMediaPicker(PlatformCapabilities caps) {
    if (caps.isWeb) return const NoopMediaPicker();
    return switch (caps.platform) {
      // `image_picker` is supported on iOS / Android only (macOS / Windows /
      // Linux would need a different adapter; degrade honestly for now).
      'ios' || 'android' => ImagePickerMediaPicker(),
      _ => const NoopMediaPicker(),
    };
  }

  static ShareService _selectShareService(PlatformCapabilities caps) {
    if (caps.isWeb) return const NoopShareService();
    return shareTargetAvailable(caps) ? const SharePlusShareService() : const NoopShareService();
  }

  static AppUpdateService _selectAppUpdateService(
    PlatformCapabilities caps, {
    required String iosAppleId,
  }) {
    if (caps.isWeb) return const NoopAppUpdateService();
    return switch (caps.platform) {
      // `in_app_update` is Android-only (Play Store). iOS uses `url_launcher`
      // against the App Store listing (Apple ID from compile-time config).
      // Both are non-blocking; the server `VersionGateStore` owns hard/soft.
      'android' => const AndroidAppUpdateService(),
      'ios' => IosAppUpdateService(appleId: iosAppleId),
      _ => const NoopAppUpdateService(),
    };
  }
}

/// Honest no-op [DeepLinkService] for test harnesses and platforms that don't
/// drive inbound URIs. The stream is empty and the cold-start initial link is
/// `null`; a test that needs to drive deep links overrides
/// [appLinkHandlerProvider] with a `StreamDeepLinkService` driven by a
/// `StreamController<Uri>`. Never the production default.
class _NoOpDeepLinkService implements DeepLinkService {
  const _NoOpDeepLinkService();

  @override
  Stream<ResolvedLink> get links => const Stream<ResolvedLink>.empty();

  @override
  Future<ResolvedLink?> getInitialLink() async => null;

  @override
  void dispose() {}
}
