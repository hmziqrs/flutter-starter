import 'package:starter/app/routing/app_link_handler.dart';
import 'package:starter/features/auth/auth_attempt_tracker.dart';
import 'package:starter/features/auth/otp_repository.dart';
import 'package:starter/features/experiments/experiment_source.dart';
import 'package:starter/features/feature_flags/feature_flags_source.dart';
import 'package:starter/features/feedback/feedback_form_value.dart';
import 'package:starter/features/feedback/feedback_transport.dart';
import 'package:starter/features/force_update/update_requirement.dart';
import 'package:starter/features/force_update/version_gate_store.dart';
import 'package:starter/features/notifications/notification_permission_status.dart';
import 'package:starter/features/notifications/notifications_repository.dart';
import 'package:starter/features/profile/profile_repository.dart';
import 'package:starter/features/session/auth_repository.dart';
import 'package:starter/features/session/auth_session.dart';
import 'package:starter/features/session/session_repository.dart';
import 'package:starter/features/settings/settings_repository.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/features/settings/settings_store.dart';
import 'package:starter/infrastructure/analytics/analytics_client.dart';
import 'package:starter/infrastructure/biometric/biometric_authenticator.dart';
import 'package:starter/infrastructure/cache/cache_store.dart';
import 'package:starter/infrastructure/connectivity/connectivity_service.dart';
import 'package:starter/infrastructure/error_reporting/crash_reporter.dart';
import 'package:starter/infrastructure/haptics/haptic_service.dart';
import 'package:starter/infrastructure/media/media_picker.dart';
import 'package:starter/infrastructure/permissions/permission_service.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';
import 'package:starter/infrastructure/platform/platform_capabilities.dart';
import 'package:starter/infrastructure/secure_storage/secure_store.dart';
import 'package:starter/infrastructure/sharing/share_service.dart';
import 'package:starter/infrastructure/updates/app_update_service.dart';

final class SettingsDependencies {
  const SettingsDependencies({
    required this.settingsRepository,
    required this.settingsStore,
    required this.initialSettings,
  });

  final SettingsRepository settingsRepository;
  final SettingsStore settingsStore;
  final SettingsState initialSettings;
}

final class StorageDependencies {
  const StorageDependencies({required this.secureStore, required this.cacheStore});

  final SecureStore secureStore;
  final CacheStore cacheStore;
}

final class AuthDependencies {
  const AuthDependencies({
    required this.authRepository,
    required this.sessionRepository,
    required this.initialSession,
    required this.otpRepository,
    required this.attemptTracker,
    required this.biometricAuthenticator,
    required this.profileRepository,
  });

  final AuthRepository authRepository;
  final SessionRepository sessionRepository;
  final AuthSession initialSession;
  final OtpRepository otpRepository;
  final AttemptTracker attemptTracker;
  final BiometricAuthenticator biometricAuthenticator;
  final ProfileRepository profileRepository;
}

final class TelemetryDependencies {
  const TelemetryDependencies({
    required this.crashReporter,
    required this.crashReporterBackend,
    required this.analyticsClient,
    required this.analyticsClientBackend,
    required this.initialAnalyticsOptIn,
  });

  final CrashReporter crashReporter;
  final CrashReporterBackend crashReporterBackend;
  final AnalyticsClient analyticsClient;
  final AnalyticsClientBackend analyticsClientBackend;
  final bool initialAnalyticsOptIn;
}

final class RemoteConfigDependencies {
  const RemoteConfigDependencies({
    required this.versionGateStore,
    required this.versionCheck,
    required this.featureFlagsSource,
    required this.experimentSource,
  });

  final VersionGateStore versionGateStore;
  final UpdateRequirement versionCheck;
  final FeatureFlagsSource featureFlagsSource;
  final ExperimentSource experimentSource;
}

final class NotificationDependencies {
  const NotificationDependencies({
    required this.notificationsRepository,
    required this.notificationsBackend,
    required this.initialNotificationPermission,
    required this.initialNotificationToken,
  });

  final NotificationsRepository notificationsRepository;
  final NotificationsBackend notificationsBackend;
  final NotificationPermissionStatus initialNotificationPermission;
  final String? initialNotificationToken;
}

final class FeedbackDependencies {
  const FeedbackDependencies({
    required this.feedbackTransport,
    required this.initialFeedbackDraft,
    required this.initialFeedbackShakeEnabled,
    required this.feedbackAppMetadata,
  });

  final FeedbackTransport feedbackTransport;
  final FeedbackDraft initialFeedbackDraft;
  final bool initialFeedbackShakeEnabled;
  final FeedbackAppMetadata feedbackAppMetadata;
}

final class PlatformDependencies {
  const PlatformDependencies({
    required this.platformCapabilities,
    required this.buildInfo,
    required this.connectivityService,
    required this.hapticService,
    required this.permissionService,
    required this.mediaPicker,
    required this.shareService,
    required this.appUpdateService,
    required this.appLinkHandler,
  });

  final PlatformCapabilities platformCapabilities;
  final AppBuildInfo? buildInfo;
  final ConnectivityService connectivityService;
  final HapticService hapticService;
  final PermissionService permissionService;
  final MediaPicker mediaPicker;
  final ShareService shareService;
  final AppUpdateService appUpdateService;
  final DeepLinkService appLinkHandler;
}
