import 'package:flutter/foundation.dart';
import 'package:starter/app/dependencies/dependency_aggregates.dart';
import 'package:starter/app/routing/app_link_handler.dart';
import 'package:starter/features/announcements/announcements_controller.dart';
import 'package:starter/features/auth/auth_attempt_tracker.dart';
import 'package:starter/features/auth/in_memory_otp_repository.dart';
import 'package:starter/features/auth/otp_repository.dart';
import 'package:starter/features/experiments/deterministic_experiment_source.dart';
import 'package:starter/features/feature_flags/in_memory_feature_flags_source.dart';
import 'package:starter/features/feedback/feedback_controller.dart';
import 'package:starter/features/feedback/feedback_form_value.dart';
import 'package:starter/features/feedback/noop_feedback_transport.dart';
import 'package:starter/features/force_update/in_memory_version_gate_store.dart';
import 'package:starter/features/force_update/update_requirement.dart';
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
import 'package:starter/infrastructure/biometric/local_auth_authenticator.dart';
import 'package:starter/infrastructure/biometric/noop_biometric_authenticator.dart';
import 'package:starter/infrastructure/cache/cache_store.dart';
import 'package:starter/infrastructure/cache/file_cache_store.dart';
import 'package:starter/infrastructure/cache/in_memory_cache_store.dart';
import 'package:starter/infrastructure/connectivity/connectivity_plus_service.dart';
import 'package:starter/infrastructure/connectivity/connectivity_service.dart';
import 'package:starter/infrastructure/connectivity/static_connectivity_service.dart';
import 'package:starter/infrastructure/devtools/inspector_host.dart';
import 'package:starter/infrastructure/devtools/stub_inspector_host.dart';
import 'package:starter/infrastructure/error_reporting/composite_crash_reporter.dart';
import 'package:starter/infrastructure/error_reporting/crash_reporter.dart';
import 'package:starter/infrastructure/error_reporting/firebase_crashlytics_crash_reporter.dart';
import 'package:starter/infrastructure/error_reporting/noop_crash_reporter.dart';
import 'package:starter/infrastructure/haptics/device_haptic_service.dart';
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
import 'package:starter/infrastructure/preferences/bool_codec.dart';
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
    required this.logger,
    required this.settings,
    required this.storage,
    required this.auth,
    required this.telemetry,
    required this.remoteConfig,
    required this.notifications,
    required this.feedback,
    required this.platform,
    required this.appStartupResult,
    required this.initialDismissedAnnouncementIds,
    this.inspectorHost = const StubInspectorHost(),
  });

  factory AppDependencies.inMemory({
    SettingsState? initialSettings,
    SettingsStore? settingsStore,
    SecureStore? secureStore,
    AuthSession? initialSession,
    PlatformCapabilities platformCapabilities = const PlatformCapabilities.nonTelevision(),
    Set<String> dismissedAnnouncementIds = const <String>{},
    ConnectivityService connectivityService = const StaticConnectivityService(),
  }) {
    final effectiveSettingsStore = settingsStore ?? InMemorySettingsStore();
    final versionGateStore = InMemoryVersionGateStore();
    final effectiveSecureStore = secureStore ?? InMemorySecureStore();
    return AppDependencies(
      logger: AppLogger.bootstrap(),
      settings: SettingsDependencies(
        settingsRepository: SettingsRepository(effectiveSettingsStore),
        settingsStore: effectiveSettingsStore,
        initialSettings:
            initialSettings ??
            const SettingsState.defaults().copyWith(hasCompletedOnboarding: true),
      ),
      storage: StorageDependencies(
        secureStore: effectiveSecureStore,
        cacheStore: InMemoryCacheStore(),
      ),
      auth: AuthDependencies(
        authRepository: InMemoryAuthRepository(),
        sessionRepository: SessionRepository(effectiveSecureStore),
        initialSession: initialSession ?? const AuthAnonymous(),
        otpRepository: const InMemoryOtpRepository(),
        attemptTracker: InMemoryAttemptTracker(),
        biometricAuthenticator: const NoopBiometricAuthenticator(),
        profileRepository: const NoopProfileRepository(),
      ),
      telemetry: TelemetryDependencies(
        crashReporter: const NoopCrashReporter(),
        crashReporterBackend: const NoopCrashReporterBackend(),
        analyticsClient: NoopAnalyticsClient(logger: AppLogger.bootstrap()),
        analyticsClientBackend: const NoopAnalyticsBackend(),
        initialAnalyticsOptIn: false,
      ),
      remoteConfig: RemoteConfigDependencies(
        versionGateStore: versionGateStore,
        versionCheck: const UpdateRequirementNone(),
        featureFlagsSource: InMemoryFeatureFlagsSource(),
        experimentSource: DeterministicExperimentSource(store: effectiveSettingsStore),
      ),
      notifications: const NotificationDependencies(
        notificationsRepository: NoopNotificationsRepository(),
        notificationsBackend: NoopNotificationsBackend(),
        initialNotificationPermission: NotificationPermissionStatus.notRequested,
        initialNotificationToken: null,
      ),
      feedback: const FeedbackDependencies(
        feedbackTransport: NoopFeedbackTransport(),
        initialFeedbackDraft: FeedbackDraft.empty(),
        initialFeedbackShakeEnabled: false,
        feedbackAppMetadata: FeedbackAppMetadata(
          appVersion: '1.0.0+1',
          platform: 'test',
          locale: 'en',
        ),
      ),
      platform: PlatformDependencies(
        platformCapabilities: platformCapabilities,
        buildInfo: const AppBuildInfo(version: '1.0.0', buildNumber: '1'),
        connectivityService: connectivityService,
        hapticService: NoopHapticService(),
        permissionService: const NoopPermissionService(),
        mediaPicker: const NoopMediaPicker(),
        shareService: const NoopShareService(),
        appUpdateService: const NoopAppUpdateService(),
        appLinkHandler: const _NoOpDeepLinkService(),
      ),
      appStartupResult: const AppStartupResult(
        buildInfo: AppBuildInfo(version: '0.0.0', buildNumber: '0'),
        settingsLoaded: true,
        localeApplied: true,
      ),
      initialDismissedAnnouncementIds: dismissedAnnouncementIds,
    );
  }

  final AppLogger logger;

  final SettingsDependencies settings;
  final StorageDependencies storage;
  final AuthDependencies auth;
  final TelemetryDependencies telemetry;
  final RemoteConfigDependencies remoteConfig;
  final NotificationDependencies notifications;
  final FeedbackDependencies feedback;
  final PlatformDependencies platform;

  final AppStartupResult appStartupResult;

  final Set<String> initialDismissedAnnouncementIds;

  final InspectorHost inspectorHost;

  AppDependencies copyWith({AppStartupResult? appStartupResult}) {
    return AppDependencies(
      logger: logger,
      settings: settings,
      storage: storage,
      auth: auth,
      telemetry: telemetry,
      remoteConfig: remoteConfig,
      notifications: notifications,
      feedback: feedback,
      platform: platform,
      appStartupResult: appStartupResult ?? this.appStartupResult,
      initialDismissedAnnouncementIds: initialDismissedAnnouncementIds,
      inspectorHost: inspectorHost,
    );
  }

  static Future<AppDependencies> production(
    AppLogger logger, {
    required String iosAppleId,
    required AllowedDeepLinkHosts allowedDeepLinkHosts,
    Uri? backendBaseUrl,
    AppBuildInfo? buildInfo,
    SecureStore? secureStore,
    PlatformCapabilitiesResolver capabilitiesResolver = const PlatformCapabilitiesResolver(),
    InspectorHost inspectorHost = const StubInspectorHost(),
    ConnectivityService? connectivityService,
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
    final initialDismissedAnnouncementIds = DismissedAnnouncements.decode(
      await settingsStore.readString(DismissedAnnouncements.key),
    );
    final versionGateStore = InMemoryVersionGateStore();
    final versionCheck = buildInfo == null
        ? const UpdateRequirementNone()
        : await versionGateStore.check(buildInfo);
    final effectiveSecureStore = secureStore ?? FlutterSecureStorageStore();
    var initialAnalyticsOptIn = false;
    try {
      initialAnalyticsOptIn = await effectiveSecureStore.readBool(analyticsOptInKey);
    } on Object catch (error, stackTrace) {
      logger.warning(
        'Unable to read analytics opt-in; defaulting to off',
        error: error,
        stackTrace: stackTrace,
      );
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
      final includeScreenshot = await settingsStore.readBool(feedbackDraftIncludeScreenshotKey);
      initialFeedbackDraft = FeedbackDraft(
        message: message ?? '',
        email: email == null || email.isEmpty ? null : email,
        includeScreenshot: includeScreenshot,
      );
    } on Object catch (error, stackTrace) {
      logger.warning(
        'Unable to read persisted feedback draft; using empty seed',
        error: error,
        stackTrace: stackTrace,
      );
      initialFeedbackDraft = const FeedbackDraft.empty();
    }
    try {
      initialFeedbackShakeEnabled = await settingsStore.readBool(feedbackShakeEnabledKey);
    } on Object catch (error, stackTrace) {
      logger.warning(
        'Unable to read shake-feedback flag; defaulting to off',
        error: error,
        stackTrace: stackTrace,
      );
      initialFeedbackShakeEnabled = false;
    }
    CacheStore cacheStore;
    if (capabilities.isWeb) {
      cacheStore = InMemoryCacheStore();
    } else {
      try {
        final cacheDir = await FileCacheStore.resolveApplicationSupportDirectory();
        cacheStore = FileCacheStore(cacheDir);
      } on Object catch (error, stackTrace) {
        logger.warning(
          'Unable to resolve cache directory; falling back to in-memory cache',
          error: error,
          stackTrace: stackTrace,
        );
        cacheStore = InMemoryCacheStore();
      }
    }
    final effectiveBuildInfo = buildInfo ?? const AppBuildInfo(version: '0.0.0', buildNumber: '0');
    final feedbackAppMetadata = FeedbackAppMetadata(
      appVersion: '${effectiveBuildInfo.version}+${effectiveBuildInfo.buildNumber}',
      platform: capabilities.platform,
      locale: settings.localeOverride?.languageTag ?? 'en',
    );
    final AuthRepository authRepository;
    final OtpRepository otpRepository;
    final ProfileRepository profileRepository;
    if (backendBaseUrl != null) {
      final dio = buildAppDio(backendBaseUrl, inspectorHost: inspectorHost, logger: logger);
      authRepository = HttpAuthClient(baseUrl: backendBaseUrl, dio: dio);
      otpRepository = HttpOtpClient(baseUrl: backendBaseUrl, dio: dio);
      profileRepository = HttpProfileRepository(baseUrl: backendBaseUrl, dio: dio);
    } else {
      authRepository = InMemoryAuthRepository();
      otpRepository = const InMemoryOtpRepository();
      profileRepository = const NoopProfileRepository();
    }
    return AppDependencies(
      logger: logger,
      settings: SettingsDependencies(
        settingsRepository: repository,
        settingsStore: settingsStore,
        initialSettings: settings,
      ),
      storage: StorageDependencies(
        secureStore: effectiveSecureStore,
        cacheStore: cacheStore,
      ),
      auth: AuthDependencies(
        authRepository: authRepository,
        sessionRepository: SessionRepository(effectiveSecureStore, logger: logger),
        initialSession: const AuthAnonymous(),
        otpRepository: otpRepository,
        attemptTracker: InMemoryAttemptTracker(),
        biometricAuthenticator: biometricAuthenticator,
        profileRepository: profileRepository,
      ),
      telemetry: TelemetryDependencies(
        crashReporter: CompositeCrashReporter(<CrashReporter>[
          const NoopCrashReporter(),
          FirebaseCrashlyticsCrashReporter(verbose: false),
        ]),
        crashReporterBackend: const NoopCrashReporterBackend(),
        analyticsClient: CompositeAnalyticsClient(<AnalyticsClient>[
          NoopAnalyticsClient(logger: logger),
          FirebaseAnalyticsClient(),
        ]),
        analyticsClientBackend: const NoopAnalyticsBackend(),
        initialAnalyticsOptIn: initialAnalyticsOptIn,
      ),
      remoteConfig: RemoteConfigDependencies(
        versionGateStore: versionGateStore,
        versionCheck: versionCheck,
        featureFlagsSource: InMemoryFeatureFlagsSource(),
        experimentSource: DeterministicExperimentSource(store: settingsStore),
      ),
      notifications: const NotificationDependencies(
        notificationsRepository: NoopNotificationsRepository(),
        notificationsBackend: NoopNotificationsBackend(),
        initialNotificationPermission: NotificationPermissionStatus.notRequested,
        initialNotificationToken: null,
      ),
      feedback: FeedbackDependencies(
        feedbackTransport: const NoopFeedbackTransport(),
        initialFeedbackDraft: initialFeedbackDraft,
        initialFeedbackShakeEnabled: initialFeedbackShakeEnabled,
        feedbackAppMetadata: feedbackAppMetadata,
      ),
      platform: PlatformDependencies(
        platformCapabilities: capabilities,
        buildInfo: buildInfo,
        connectivityService: connectivityService ?? ConnectivityPlusService(logger: logger),
        hapticService: const DeviceHapticService(),
        permissionService: _selectPermissionService(capabilities, logger: logger),
        mediaPicker: _selectMediaPicker(capabilities, logger: logger),
        shareService: _selectShareService(capabilities, logger: logger),
        appUpdateService: _selectAppUpdateService(
          capabilities,
          iosAppleId: iosAppleId,
          logger: logger,
        ),
        appLinkHandler: AppLinksDeepLinkService(
          handler: RouteAppLinkHandler(allowedHosts: allowedDeepLinkHosts),
        ),
      ),
      appStartupResult: AppStartupResult(
        buildInfo: buildInfo ?? const AppBuildInfo(version: '0.0.0', buildNumber: '0'),
        settingsLoaded: settingsLoaded,
        localeApplied: true,
      ),
      initialDismissedAnnouncementIds: initialDismissedAnnouncementIds,
      inspectorHost: inspectorHost,
    );
  }

  static PermissionService _selectPermissionService(
    PlatformCapabilities caps, {
    required AppLogger logger,
  }) {
    if (caps.isWeb) return const NoopPermissionService();
    return switch (caps.platform) {
      'ios' || 'android' => DevicePermissionService(logger: logger),
      _ => const NoopPermissionService(),
    };
  }

  static MediaPicker _selectMediaPicker(
    PlatformCapabilities caps, {
    required AppLogger logger,
  }) {
    if (caps.isWeb) return const NoopMediaPicker();
    return switch (caps.platform) {
      'ios' || 'android' => ImagePickerMediaPicker(logger: logger),
      _ => const NoopMediaPicker(),
    };
  }

  static ShareService _selectShareService(
    PlatformCapabilities caps, {
    required AppLogger logger,
  }) {
    if (caps.isWeb) return const NoopShareService();
    return shareTargetAvailable(caps)
        ? SharePlusShareService(logger: logger)
        : const NoopShareService();
  }

  static AppUpdateService _selectAppUpdateService(
    PlatformCapabilities caps, {
    required String iosAppleId,
    required AppLogger logger,
  }) {
    if (caps.isWeb) return const NoopAppUpdateService();
    return switch (caps.platform) {
      'android' => AndroidAppUpdateService(logger: logger),
      'ios' => IosAppUpdateService(appleId: iosAppleId, logger: logger),
      _ => const NoopAppUpdateService(),
    };
  }
}

class _NoOpDeepLinkService implements DeepLinkService {
  const _NoOpDeepLinkService();

  @override
  Stream<ResolvedLink> get links => const Stream<ResolvedLink>.empty();

  @override
  Future<ResolvedLink?> getInitialLink() async => null;

  @override
  void dispose() {}
}
