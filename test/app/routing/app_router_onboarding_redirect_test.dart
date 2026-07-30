import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/app/app.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/config/app_environment.dart';
import 'package:starter/app/dependencies.dart';
import 'package:starter/app/routing/app_link_handler.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/features/announcements/announcement_fixtures.dart';
import 'package:starter/features/auth/auth_attempt_tracker.dart';
import 'package:starter/features/auth/in_memory_otp_repository.dart';
import 'package:starter/features/experiments/deterministic_experiment_source.dart';
import 'package:starter/features/feature_flags/in_memory_feature_flags_source.dart';
import 'package:starter/features/feedback/feedback_form_value.dart';
import 'package:starter/features/feedback/noop_feedback_transport.dart';
import 'package:starter/features/force_update/in_memory_version_gate_store.dart';
import 'package:starter/features/force_update/update_requirement.dart';
import 'package:starter/features/notifications/noop_notifications_repository.dart';
import 'package:starter/features/notifications/notification_permission_status.dart';
import 'package:starter/features/notifications/notifications_repository.dart';
import 'package:starter/features/profile/noop_profile_repository.dart';
import 'package:starter/features/security/in_memory_secure_store.dart';
import 'package:starter/features/session/auth_session.dart';
import 'package:starter/features/session/in_memory_auth_repository.dart';
import 'package:starter/features/session/session_repository.dart';
import 'package:starter/features/settings/in_memory_settings_store.dart';
import 'package:starter/features/settings/settings_repository.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/features/splash/app_startup_result.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/analytics/analytics_client.dart';
import 'package:starter/infrastructure/analytics/noop_analytics_client.dart';
import 'package:starter/infrastructure/biometric/noop_biometric_authenticator.dart';
import 'package:starter/infrastructure/cache/in_memory_cache_store.dart';
import 'package:starter/infrastructure/error_reporting/crash_reporter.dart';
import 'package:starter/infrastructure/error_reporting/noop_crash_reporter.dart';
import 'package:starter/infrastructure/haptics/noop_haptic_service.dart';
import 'package:starter/infrastructure/logging/app_logger.dart';
import 'package:starter/infrastructure/media/noop_media_picker.dart';
import 'package:starter/infrastructure/permissions/noop_permission_service.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';
import 'package:starter/infrastructure/platform/platform_capabilities.dart';
import 'package:starter/infrastructure/sharing/noop_share_service.dart';
import 'package:starter/infrastructure/updates/noop_app_update_service.dart';
import '../../infrastructure/connectivity/fake_connectivity_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => LocaleSettings.setLocale(AppLocale.en));

  testWidgets('fresh install boots to onboarding instead of home (cold-start redirect)', (
    tester,
  ) async {
    await _pumpApp(tester, _freshInstallDependencies());

    // The router's top-level redirect sends / -> /onboarding when the live
    // settingsControllerProvider flag is unset.
    expect(find.byKey(const ValueKey('onboarding-skip')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-greeting')), findsNothing);
  });

  testWidgets('returning user (flag already complete) boots straight to home', (tester) async {
    await _pumpApp(
      tester,
      _dependencies(
        initialSettings: const SettingsState.defaults().copyWith(hasCompletedOnboarding: true),
      ),
    );

    expect(find.byKey(const ValueKey('home-greeting')), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding-skip')), findsNothing);
  });

  testWidgets('in-session Skip marks onboarding complete and reaches home WITHOUT a '
      'relaunch (regresses the captured-bool loop)', (tester) async {
    // A captured-bool redirect would re-evaluate against the stale pre-mark
    // value on the subsequent goNamed(home) and bounce home -> onboarding.
    // The live read must observe the optimistic write on the same tick.
    await _pumpApp(tester, _freshInstallDependencies());
    expect(find.byKey(const ValueKey('onboarding-skip')), findsOneWidget);

    await _tapVisible(tester, const ValueKey('onboarding-skip'));
    await _pumpAppFrames(tester);

    expect(find.byKey(const ValueKey('home-greeting')), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding-skip')), findsNothing);
  });

  testWidgets('paywall Skip marks onboarding complete and reaches home in-session', (tester) async {
    await _pumpApp(
      tester,
      _freshInstallDependencies(),
      initialLocation: AppRoutes.onboardingPaywallPath,
    );
    expect(find.byKey(const ValueKey('paywall-skip')), findsOneWidget);

    await _tapVisible(tester, const ValueKey('paywall-skip'));
    await _pumpAppFrames(tester);

    expect(find.byKey(const ValueKey('home-greeting')), findsOneWidget);
  });

  testWidgets('paywall Continue marks onboarding complete and reaches home in-session', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      _freshInstallDependencies(),
      initialLocation: AppRoutes.onboardingPaywallPath,
    );
    expect(find.byKey(const ValueKey('paywall-continue')), findsOneWidget);

    await _tapVisible(tester, const ValueKey('paywall-continue'));
    await _pumpAppFrames(tester);

    expect(find.byKey(const ValueKey('home-greeting')), findsOneWidget);
  });

  testWidgets('fresh-install deep link to /pricing redirects to onboarding', (tester) async {
    await _pumpApp(
      tester,
      _freshInstallDependencies(),
      initialLocation: AppRoutes.pricingPath,
    );

    expect(find.byKey(const ValueKey('onboarding-skip')), findsOneWidget);
    expect(find.byKey(const ValueKey('pricing-page')), findsNothing);
  });

  testWidgets('fresh-install deep link to /settings redirects to onboarding', (tester) async {
    await _pumpApp(
      tester,
      _freshInstallDependencies(),
      initialLocation: AppRoutes.settingsPath,
    );

    expect(find.byKey(const ValueKey('onboarding-skip')), findsOneWidget);
  });

  testWidgets('already on onboarding: no redirect loop (onboarding routes are excluded '
      'from the gate)', (tester) async {
    await _pumpApp(
      tester,
      _freshInstallDependencies(),
      initialLocation: AppRoutes.onboardingPath,
    );

    expect(find.byKey(const ValueKey('onboarding-skip')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-greeting')), findsNothing);
  });

  testWidgets('auth routes are not hijacked by the onboarding gate on fresh install', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      _freshInstallDependencies(),
      initialLocation: AppRoutes.loginPath,
    );

    // Login renders directly — auth flows are not bounced into onboarding.
    expect(find.byKey(const ValueKey('onboarding-skip')), findsNothing);
  });

  testWidgets('detail routes reachable from the shell do not redirect independently', (
    tester,
  ) async {
    // /profile/edit is not a shell-tab destination; the onboarding gate leaves
    // it alone (the shell itself guards entry).
    await _pumpApp(
      tester,
      _freshInstallDependencies(),
      initialLocation: AppRoutes.updateProfilePath,
    );

    expect(find.byKey(const ValueKey('onboarding-skip')), findsNothing);
  });

  testWidgets('after markOnboardingComplete + relaunch (reload from the same store), '
      'boots straight to home', (tester) async {
    // Share an InMemorySettingsStore across both App instances so the persisted
    // "true" survives the relaunch.
    final store = InMemorySettingsStore();

    // First boot: fresh install -> onboarding.
    await _pumpApp(
      tester,
      _dependencies(store: store),
    );
    expect(find.byKey(const ValueKey('onboarding-skip')), findsOneWidget);

    // Skip -> optimistic write hits the shared store -> home in-session.
    await _tapVisible(tester, const ValueKey('onboarding-skip'));
    await _pumpAppFrames(tester);
    expect(find.byKey(const ValueKey('home-greeting')), findsOneWidget);
    expect(store.snapshot[SettingsRepository.onboardingKey], 'true');

    // Tear down the first widget tree, then reload from the same store.
    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpAppFrames(tester);

    final reloadedSettings = await SettingsRepository(store).load();
    expect(reloadedSettings.hasCompletedOnboarding, isTrue);

    await _pumpApp(
      tester,
      _dependencies(store: store, initialSettings: reloadedSettings),
    );

    // Returning-user boot: home directly, no onboarding redirect.
    expect(find.byKey(const ValueKey('home-greeting')), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding-skip')), findsNothing);
  });
}

final _productionConfig = AppConfig(
  environment: AppEnvironment.production,
  enableVerboseLogging: false,
  enableDevTools: false,
  iosAppleId: '',
  allowedDeepLinkHosts: AllowedDeepLinkHosts.empty,
);

AppDependencies _freshInstallDependencies() => _dependencies();

AppDependencies _dependencies({
  SettingsState? initialSettings,
  InMemorySettingsStore? store,
}) {
  final settingsStore = store ?? InMemorySettingsStore();
  final secureStore = InMemorySecureStore();
  return AppDependencies(
    settingsRepository: SettingsRepository(settingsStore),
    settingsStore: settingsStore,
    initialSettings: initialSettings ?? const SettingsState.defaults(),
    secureStore: secureStore,
    crashReporter: const NoopCrashReporter(),
    crashReporterBackend: const NoopCrashReporterBackend(),
    // No-backend test defaults: the version gate never blocks (C2: never fake a
    // block) and the connectivity sensor is online so the banner stays hidden.
    versionGateStore: InMemoryVersionGateStore(),
    versionCheck: const UpdateRequirementNone(),
    connectivityService: FakeConnectivityService(),
    // Wave-4 no-backend defaults mirror AppDependencies.inMemory: the auth repo
    // surfaces notConnected unseeded, analytics is noop, feature-flags fall back
    // to defaults, and the biometric authenticator is the honest noop.
    authRepository: InMemoryAuthRepository(),
    sessionRepository: SessionRepository(secureStore),
    initialSession: const AuthAnonymous(),
    analyticsClient: NoopAnalyticsClient(logger: AppLogger.bootstrap()),
    analyticsClientBackend: const NoopAnalyticsBackend(),
    initialAnalyticsOptIn: false,
    featureFlagsSource: InMemoryFeatureFlagsSource(),
    biometricAuthenticator: const NoopBiometricAuthenticator(),
    attemptTracker: InMemoryAttemptTracker(),
    // Haptics: Noop keeps the redirect test hermetic (a tap never reaches the
    // platform channel). Mirrors AppDependencies.inMemory.
    hapticService: NoopHapticService(),
    // Splash seed mirrors AppDependencies.inMemory: a resolved success so the
    // onboarding-redirect path under test boots without re-running init.
    appStartupResult: const AppStartupResult(
      buildInfo: AppBuildInfo(version: '0.0.0', buildNumber: '0'),
      settingsLoaded: true,
      localeApplied: true,
    ),
    buildInfo: const AppBuildInfo(version: '1.0.0', buildNumber: '1'),
    // The floating announcement banner overlaps the top of the screen; dismiss
    // the whole feed so it never occludes the routing targets these cases tap.
    initialDismissedAnnouncementIds: AnnouncementFixtures.standard.map((a) => a.id).toSet(),
    // Wave-5b no-backend test defaults: each port degrades honestly (never
    // fakes a grant / pick / share / update / token); the deep-link service
    // is a no-op so the redirect path under test is unaffected.
    otpRepository: const InMemoryOtpRepository(),
    // Profile port: honest no-backend default mirrors AppDependencies.inMemory
    // (surfaces notConnected; the route is auth-gated and unreachable here).
    profileRepository: const NoopProfileRepository(),
    notificationsRepository: const NoopNotificationsRepository(),
    notificationsBackend: const NoopNotificationsBackend(),
    initialNotificationPermission: NotificationPermissionStatus.notRequested,
    initialNotificationToken: null,
    permissionService: const NoopPermissionService(),
    mediaPicker: const NoopMediaPicker(),
    shareService: const NoopShareService(),
    appUpdateService: const NoopAppUpdateService(),
    appLinkHandler: const _NoOpDeepLinkService(),
    // Wave-6 no-backend test defaults: honest local/in-memory choices so the
    // redirect path under test never fakes a backend success (C2). Mirrors
    // AppDependencies.inMemory.
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
    platformCapabilities: const PlatformCapabilities.nonTelevision(),
  );
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

Future<void> _pumpApp(
  WidgetTester tester,
  AppDependencies dependencies, {
  String initialLocation = AppRoutes.homePath,
}) async {
  await tester.pumpWidget(
    App(
      config: _productionConfig,
      dependencies: dependencies,
      initialLocation: initialLocation,
    ),
  );
  await _pumpAppFrames(tester);
}

/// Bounded frame pump mirroring integration_test_support.dart's pumpAppFrames.
/// pumpAndSettle is avoided: focused editables or platform animations can keep
/// scheduling frames indefinitely while the state under test is already ready.
Future<void> _pumpAppFrames(WidgetTester tester) async {
  for (var frame = 0; frame < 8; frame += 1) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Scrolls the target into view, unfocuses any active editable, then taps.
/// Mirrors `tapVisible` from integration_test_support.dart — the onboarding /
/// paywall CTAs sit below the fold on the default 800x600 test viewport.
Future<void> _tapVisible(WidgetTester tester, Key key) async {
  final target = find.byKey(key);
  tester.binding.focusManager.primaryFocus?.unfocus();
  await tester.pump();
  await tester.ensureVisible(target);
  await _pumpAppFrames(tester);
  await tester.tap(target.hitTestable());
  await _pumpAppFrames(tester);
}
