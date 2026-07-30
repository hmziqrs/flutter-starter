import 'package:flutter/foundation.dart';
import 'package:starter/app/routing/app_link_handler.dart';
import 'package:starter/features/announcements/announcements_controller.dart';
import 'package:starter/features/auth/auth_attempt_tracker.dart';
import 'package:starter/features/auth/in_memory_otp_repository.dart';
import 'package:starter/features/auth/otp_repository.dart';
import 'package:starter/features/experiments/deterministic_experiment_source.dart';
import 'package:starter/features/experiments/experiment_source.dart';
import 'package:starter/features/feature_flags/feature_flags_source.dart';
import 'package:starter/features/feature_flags/in_memory_feature_flags_source.dart';
import 'package:starter/features/feedback/feedback_controller.dart';
import 'package:starter/features/feedback/feedback_form_value.dart';
import 'package:starter/features/feedback/feedback_transport.dart';
import 'package:starter/features/feedback/noop_feedback_transport.dart';
import 'package:starter/features/force_update/in_memory_version_gate_store.dart';
import 'package:starter/features/force_update/update_requirement.dart';
import 'package:starter/features/force_update/version_gate_store.dart';
import 'package:starter/features/notifications/noop_notifications_repository.dart';
import 'package:starter/features/notifications/notification_permission_status.dart';
import 'package:starter/features/notifications/notifications_repository.dart';
import 'package:starter/features/profile/noop_profile_repository.dart';
import 'package:starter/features/profile/profile_repository.dart';
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
import 'package:starter/infrastructure/analytics/composite_analytics_client.dart';
import 'package:starter/infrastructure/analytics/firebase_analytics_client.dart';
import 'package:starter/infrastructure/analytics/noop_analytics_client.dart';
import 'package:starter/infrastructure/auth/http_auth_client.dart';
import 'package:starter/infrastructure/auth/http_otp_client.dart';
import 'package:starter/infrastructure/biometric/biometric_authenticator.dart';
import 'package:starter/infrastructure/biometric/local_auth_authenticator.dart';
import 'package:starter/infrastructure/biometric/noop_biometric_authenticator.dart';
import 'package:starter/infrastructure/cache/cache_store.dart';
import 'package:starter/infrastructure/cache/file_cache_store.dart';
import 'package:starter/infrastructure/cache/in_memory_cache_store.dart';
import 'package:starter/infrastructure/connectivity/connectivity_plus_service.dart';
import 'package:starter/infrastructure/connectivity/connectivity_service.dart';
import 'package:starter/infrastructure/devtools/inspector_host.dart';
import 'package:starter/infrastructure/devtools/stub_inspector_host.dart';
import 'package:starter/infrastructure/error_reporting/composite_crash_reporter.dart';
import 'package:starter/infrastructure/error_reporting/crash_reporter.dart';
import 'package:starter/infrastructure/error_reporting/firebase_crashlytics_crash_reporter.dart';
import 'package:starter/infrastructure/error_reporting/noop_crash_reporter.dart';
import 'package:starter/infrastructure/haptics/device_haptic_service.dart';
import 'package:starter/infrastructure/haptics/haptic_service.dart';
import 'package:starter/infrastructure/haptics/noop_haptic_service.dart';
import 'package:starter/infrastructure/http/app_dio.dart';
import 'package:starter/infrastructure/logging/app_logger.dart';
import 'package:starter/infrastructure/media/image_picker_media_picker.dart';
import 'package:starter/infrastructure/media/media_picker.dart';
import 'package:starter/infrastructure/media/noop_media_picker.dart';
import 'package:starter/infrastructure/permissions/device_permission_service.dart';
import 'package:starter/infrastructure/permissions/noop_permission_service.dart';
import 'package:starter/infrastructure/permissions/permission_service.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';
import 'package:starter/infrastructure/platform/platform_capabilities.dart';
import 'package:starter/infrastructure/platform/platform_capabilities_resolver.dart';
import 'package:starter/infrastructure/preferences/shared_preferences_settings_store.dart';
import 'package:starter/infrastructure/profile/http_profile_repository.dart';
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
    required this.profileRepository,
    required this.notificationsRepository,
    required this.notificationsBackend,
    required this.initialNotificationPermission,
    required this.initialNotificationToken,
    required this.permissionService,
    required this.mediaPicker,
    required this.shareService,
    required this.appUpdateService,
    required this.appLinkHandler,
    required this.experimentSource,
    required this.cacheStore,
    required this.feedbackTransport,
    required this.initialFeedbackDraft,
    required this.initialFeedbackShakeEnabled,
    required this.feedbackAppMetadata,
    required this.platformCapabilities,
    this.inspectorHost = const StubInspectorHost(),
  });

  factory AppDependencies.inMemory({
    SettingsState? initialSettings,
    SecureStore? secureStore,
    AuthSession? initialSession,
    PlatformCapabilities platformCapabilities = const PlatformCapabilities.nonTelevision(),
    Set<String> dismissedAnnouncementIds = const <String>{},
  }) {
    final settingsStore = InMemorySettingsStore();
    final versionGateStore = InMemoryVersionGateStore();
    final effectiveSecureStore = secureStore ?? InMemorySecureStore();
    return AppDependencies(
      settingsRepository: SettingsRepository(settingsStore),
      settingsStore: settingsStore,
      // Defaults to a returning user who has completed onboarding, so shell /
      // navigation / gallery suites boot straight to home. The fresh-install
      // redirect is covered independently by app_router_onboarding_redirect_test.dart.
      initialSettings:
          initialSettings ?? const SettingsState.defaults().copyWith(hasCompletedOnboarding: true),
      secureStore: effectiveSecureStore,
      crashReporter: const NoopCrashReporter(),
      crashReporterBackend: const NoopCrashReporterBackend(),
      versionGateStore: versionGateStore,
      versionCheck: const UpdateRequirementNone(),
      // Real local connectivity_plus sensor, not a Noop: safe in integration
      // tests on a real platform; widget tests override the provider instead.
      connectivityService: ConnectivityPlusService(),
      appStartupResult: const AppStartupResult(
        buildInfo: AppBuildInfo(version: '0.0.0', buildNumber: '0'),
        settingsLoaded: true,
        localeApplied: true,
      ),
      buildInfo: const AppBuildInfo(version: '1.0.0', buildNumber: '1'),
      // No dismissed announcements by default, so the first fixture surfaces
      // and exercises the floating banner in a full-app pump.
      initialDismissedAnnouncementIds: dismissedAnnouncementIds,
      authRepository: InMemoryAuthRepository(),
      sessionRepository: SessionRepository(effectiveSecureStore),
      initialSession: initialSession ?? const AuthAnonymous(),
      analyticsClient: NoopAnalyticsClient(logger: AppLogger.bootstrap()),
      analyticsClientBackend: const NoopAnalyticsBackend(),
      initialAnalyticsOptIn: false,
      featureFlagsSource: InMemoryFeatureFlagsSource(),
      biometricAuthenticator: const NoopBiometricAuthenticator(),
      attemptTracker: InMemoryAttemptTracker(),
      hapticService: NoopHapticService(),
      otpRepository: const InMemoryOtpRepository(),
      profileRepository: const NoopProfileRepository(),
      notificationsRepository: const NoopNotificationsRepository(),
      notificationsBackend: const NoopNotificationsBackend(),
      initialNotificationPermission: NotificationPermissionStatus.notRequested,
      initialNotificationToken: null,
      permissionService: const NoopPermissionService(),
      mediaPicker: const NoopMediaPicker(),
      shareService: const NoopShareService(),
      appUpdateService: const NoopAppUpdateService(),
      // Tests don't drive inbound URIs; a test that needs to overrides the
      // provider directly with a stream-backed service.
      appLinkHandler: const _NoOpDeepLinkService(),
      experimentSource: DeterministicExperimentSource(store: settingsStore),
      cacheStore: InMemoryCacheStore(),
      feedbackTransport: const NoopFeedbackTransport(),
      initialFeedbackDraft: const FeedbackDraft.empty(),
      initialFeedbackShakeEnabled: false,
      feedbackAppMetadata: const FeedbackAppMetadata(
        appVersion: '1.0.0+1',
        platform: 'test',
        locale: 'en',
      ),
      platformCapabilities: platformCapabilities,
    );
  }

  final SettingsRepository settingsRepository;
  final SettingsStore settingsStore;
  final SettingsState initialSettings;
  final PlatformCapabilities platformCapabilities;
  final SecureStore secureStore;
  final CrashReporter crashReporter;
  final CrashReporterBackend crashReporterBackend;
  final VersionGateStore versionGateStore;
  final UpdateRequirement versionCheck;
  final ConnectivityService connectivityService;

  /// Summary of work `createApplication` already performs (build-info load,
  /// settings load, locale apply) so SplashPage can observe it without
  /// re-running any of it. `localeApplied` is finalized via [copyWith] once
  /// the locale apply runs, since that happens after this factory returns.
  final AppStartupResult appStartupResult;

  /// The installed build, reused for the announcements version window instead
  /// of reading `PackageInfo` a second time.
  final AppBuildInfo? buildInfo;

  /// Cold-start seed of dismissed announcement ids, pre-loaded so the
  /// controller resolves synchronously.
  final Set<String> initialDismissedAnnouncementIds;

  final AuthRepository authRepository;
  final SessionRepository sessionRepository;
  final AuthSession initialSession;

  final AnalyticsClient analyticsClient;
  final AnalyticsClientBackend analyticsClientBackend;
  final bool initialAnalyticsOptIn;

  final FeatureFlagsSource featureFlagsSource;

  final BiometricAuthenticator biometricAuthenticator;

  /// Local per-identifier attempt/lockout tracker (UX-only, pure-Dart). Fresh
  /// per launch; shared by login, OTP, and the future pin-autolock surface.
  final AttemptTracker attemptTracker;

  final HapticService hapticService;

  final OtpRepository otpRepository;

  final ProfileRepository profileRepository;

  final NotificationsRepository notificationsRepository;
  final NotificationsBackend notificationsBackend;
  final NotificationPermissionStatus initialNotificationPermission;
  final String? initialNotificationToken;

  final PermissionService permissionService;

  final MediaPicker mediaPicker;

  final ShareService shareService;

  /// Non-blocking OS-store update prompt; the server [VersionGateStore] owns
  /// the hard/soft block, so this never double-blocks.
  final AppUpdateService appUpdateService;

  final DeepLinkService appLinkHandler;

  /// Must share the production `settingsStore` so the stable device id used
  /// for assignment stays consistent.
  final ExperimentSource experimentSource;

  final CacheStore cacheStore;

  final FeedbackTransport feedbackTransport;

  /// Pre-loaded so the controller resolves synchronously on the first frame.
  final FeedbackDraft initialFeedbackDraft;

  final bool initialFeedbackShakeEnabled;

  final FeedbackAppMetadata feedbackAppMetadata;

  /// Dev-only HTTP inspector host, chosen by the build entrypoint: production
  /// wires [StubInspectorHost] (no `dio_request_inspector` import, so the
  /// package is absent from release AOT — avoids the flutter/flutter#188060
  /// snapshotter crash); development wires a `RealInspectorHost`. Threaded to
  /// `bootstrap` (overlay wrapper), [buildAppDio] (interceptor), and `App`
  /// (navigator observers).
  final InspectorHost inspectorHost;

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
      profileRepository: profileRepository,
      notificationsRepository: notificationsRepository,
      notificationsBackend: notificationsBackend,
      initialNotificationPermission: initialNotificationPermission,
      initialNotificationToken: initialNotificationToken,
      permissionService: permissionService,
      mediaPicker: mediaPicker,
      shareService: shareService,
      appUpdateService: appUpdateService,
      appLinkHandler: appLinkHandler,
      experimentSource: experimentSource,
      cacheStore: cacheStore,
      feedbackTransport: feedbackTransport,
      initialFeedbackDraft: initialFeedbackDraft,
      initialFeedbackShakeEnabled: initialFeedbackShakeEnabled,
      feedbackAppMetadata: feedbackAppMetadata,
      platformCapabilities: platformCapabilities,
      inspectorHost: inspectorHost,
    );
  }

  static Future<AppDependencies> production(
    AppLogger logger, {
    required String iosAppleId,
    required AllowedDeepLinkHosts allowedDeepLinkHosts,
    Uri? backendBaseUrl,
    AppBuildInfo? buildInfo,
    // Null uses the production FlutterSecureStorageStore; a headless
    // integration test (no secret-service daemon) injects an in-memory store
    // so the flow never touches libsecret.
    SecureStore? secureStore,
    PlatformCapabilitiesResolver capabilitiesResolver = const PlatformCapabilitiesResolver(),
    InspectorHost inspectorHost = const StubInspectorHost(),
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
      );
    }

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
    // Pre-loaded so AnnouncementsController resolves synchronously; malformed
    // storage degrades to "nothing dismissed" rather than throwing.
    final initialDismissedAnnouncementIds = DismissedAnnouncements.decode(
      await settingsStore.readString(DismissedAnnouncements.key),
    );
    final versionGateStore = InMemoryVersionGateStore();
    final versionCheck = buildInfo == null
        ? const UpdateRequirementNone()
        : await versionGateStore.check(buildInfo);
    // Shared by the session repository and the analytics opt-in pre-load so
    // the keychain is opened once.
    final effectiveSecureStore = secureStore ?? FlutterSecureStorageStore();
    var initialAnalyticsOptIn = false;
    try {
      initialAnalyticsOptIn = await effectiveSecureStore.read(analyticsOptInKey) == 'true';
    } on Object {
      initialAnalyticsOptIn = false;
    }
    final biometricAuthenticator = capabilities.isWeb
        ? const NoopBiometricAuthenticator()
        : LocalAuthAuthenticator();
    var initialFeedbackDraft = const FeedbackDraft.empty();
    var initialFeedbackShakeEnabled = false;
    try {
      final message = await settingsStore.readString(feedbackDraftMessageKey);
      final email = await settingsStore.readString(feedbackDraftEmailKey);
      final includeScreenshot = await settingsStore.readString(feedbackDraftIncludeScreenshotKey);
      initialFeedbackDraft = FeedbackDraft(
        message: message ?? '',
        email: email == null || email.isEmpty ? null : email,
        includeScreenshot: includeScreenshot == 'true',
      );
    } on Object {
      initialFeedbackDraft = const FeedbackDraft.empty();
    }
    try {
      initialFeedbackShakeEnabled =
          await settingsStore.readString(feedbackShakeEnabledKey) == 'true';
    } on Object {
      initialFeedbackShakeEnabled = false;
    }
    // Web falls back to in-memory (path_provider is unsupported); a
    // directory-resolution failure also degrades to in-memory.
    CacheStore cacheStore;
    if (capabilities.isWeb) {
      cacheStore = InMemoryCacheStore();
    } else {
      try {
        final cacheDir = await FileCacheStore.resolveApplicationSupportDirectory();
        cacheStore = FileCacheStore(cacheDir);
      } on Object {
        cacheStore = InMemoryCacheStore();
      }
    }
    final effectiveBuildInfo = buildInfo ?? const AppBuildInfo(version: '0.0.0', buildNumber: '0');
    final feedbackAppMetadata = FeedbackAppMetadata(
      appVersion: '${effectiveBuildInfo.version}+${effectiveBuildInfo.buildNumber}',
      platform: capabilities.platform,
      locale: settings.localeOverride?.languageTag ?? 'en',
    );
    // When a backend URL is configured the real HTTP adapters are constructed
    // against it; otherwise the no-backend defaults surface notConnected.
    final AuthRepository authRepository;
    final OtpRepository otpRepository;
    final ProfileRepository profileRepository;
    if (backendBaseUrl != null) {
      // One shared Dio (connection pooling + a single dev overlay) for all
      // three session-coupled adapters.
      final dio = buildAppDio(backendBaseUrl, inspectorHost: inspectorHost);
      authRepository = HttpAuthClient(baseUrl: backendBaseUrl, dio: dio);
      otpRepository = HttpOtpClient(baseUrl: backendBaseUrl, dio: dio);
      profileRepository = HttpProfileRepository(baseUrl: backendBaseUrl, dio: dio);
    } else {
      authRepository = InMemoryAuthRepository();
      otpRepository = const InMemoryOtpRepository();
      profileRepository = const NoopProfileRepository();
    }
    return AppDependencies(
      settingsRepository: repository,
      settingsStore: settingsStore,
      initialSettings: settings,
      secureStore: effectiveSecureStore,
      // FirebaseCrashlyticsCrashReporter self-disables on web/Linux/Windows and
      // when Firebase is not initialized, so the composite is safe with the
      // Noop-only existing arm.
      crashReporter: CompositeCrashReporter(<CrashReporter>[
        const NoopCrashReporter(),
        FirebaseCrashlyticsCrashReporter(verbose: false),
      ]),
      crashReporterBackend: const NoopCrashReporterBackend(),
      versionGateStore: versionGateStore,
      versionCheck: versionCheck,
      connectivityService: ConnectivityPlusService(),
      // `localeApplied` is optimistic here; `createApplication` finalizes it
      // via copyWith once the locale apply (which runs after this returns)
      // is known to have failed.
      appStartupResult: AppStartupResult(
        buildInfo: buildInfo ?? const AppBuildInfo(version: '0.0.0', buildNumber: '0'),
        settingsLoaded: settingsLoaded,
        localeApplied: true,
      ),
      buildInfo: buildInfo,
      initialDismissedAnnouncementIds: initialDismissedAnnouncementIds,
      authRepository: authRepository,
      sessionRepository: SessionRepository(effectiveSecureStore),
      initialSession: const AuthAnonymous(),
      // FirebaseAnalyticsClient self-disables on Linux/Windows and when
      // Firebase is not initialized, so the composite is safe with the
      // Noop-only existing arm.
      analyticsClient: CompositeAnalyticsClient(<AnalyticsClient>[
        NoopAnalyticsClient(logger: logger),
        FirebaseAnalyticsClient(),
      ]),
      analyticsClientBackend: const NoopAnalyticsBackend(),
      initialAnalyticsOptIn: initialAnalyticsOptIn,
      featureFlagsSource: InMemoryFeatureFlagsSource(),
      biometricAuthenticator: biometricAuthenticator,
      attemptTracker: InMemoryAttemptTracker(),
      hapticService: const DeviceHapticService(),
      otpRepository: otpRepository,
      profileRepository: profileRepository,
      // Firebase adapter is a consumer override on iOS/Android with
      // credentials only; firebase_messaging has no desktop/web support.
      notificationsRepository: const NoopNotificationsRepository(),
      notificationsBackend: const NoopNotificationsBackend(),
      initialNotificationPermission: NotificationPermissionStatus.notRequested,
      initialNotificationToken: null,
      permissionService: _selectPermissionService(capabilities),
      mediaPicker: _selectMediaPicker(capabilities),
      shareService: _selectShareService(capabilities),
      appUpdateService: _selectAppUpdateService(capabilities, iosAppleId: iosAppleId),
      // Web is handled by MaterialApp.router's browser URL bar instead; the
      // cold-start getInitialLink is captured in bootstrap.dart.
      appLinkHandler: AppLinksDeepLinkService(
        handler: RouteAppLinkHandler(allowedHosts: allowedDeepLinkHosts),
      ),
      experimentSource: DeterministicExperimentSource(store: settingsStore),
      cacheStore: cacheStore,
      feedbackTransport: const NoopFeedbackTransport(),
      initialFeedbackDraft: initialFeedbackDraft,
      initialFeedbackShakeEnabled: initialFeedbackShakeEnabled,
      feedbackAppMetadata: feedbackAppMetadata,
      platformCapabilities: capabilities,
      inspectorHost: inspectorHost,
    );
  }

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
