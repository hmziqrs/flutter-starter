import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:starter/app/app_lifecycle_controller.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/dependencies.dart';
import 'package:starter/app/interaction_policy_controller.dart';
import 'package:starter/app/keyboard/app_keyboard_host.dart';
import 'package:starter/app/last_route.dart';
import 'package:starter/app/platform_capabilities_provider.dart';
import 'package:starter/app/presentation/app_presentation_viewport.dart';
import 'package:starter/app/presentation_policy_controller.dart';
import 'package:starter/app/routing/app_link_handler.dart';
import 'package:starter/app/routing/app_router.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/features/announcements/announcement_banner.dart';
import 'package:starter/features/announcements/announcements_controller.dart';
import 'package:starter/features/auth/auth_attempt_tracker.dart';
import 'package:starter/features/auth/otp_repository.dart';
import 'package:starter/features/connectivity/connectivity_banner.dart';
import 'package:starter/features/connectivity/connectivity_controller.dart';
import 'package:starter/features/experiments/experiment_source.dart';
import 'package:starter/features/feature_flags/feature_flags_source.dart';
import 'package:starter/features/feedback/feedback_controller.dart';
import 'package:starter/features/feedback/feedback_sheet.dart';
import 'package:starter/features/feedback/feedback_transport.dart';
import 'package:starter/features/feedback/shake_feedback_trigger.dart';
import 'package:starter/features/force_update/version_gate_providers.dart';
import 'package:starter/features/notifications/notification_tap.dart';
import 'package:starter/features/notifications/notifications_controller.dart';
import 'package:starter/features/notifications/notifications_repository.dart';
import 'package:starter/features/profile/profile_repository.dart';
import 'package:starter/features/security/auto_lock_controller.dart';
import 'package:starter/features/session/session_controller.dart';
import 'package:starter/features/settings/analytics_opt_in_controller.dart';
import 'package:starter/features/settings/settings_controller.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/features/settings/settings_store.dart';
import 'package:starter/features/splash/app_startup_result_provider.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/analytics/analytics_client.dart';
import 'package:starter/infrastructure/analytics/analytics_route_observer.dart';
import 'package:starter/infrastructure/biometric/biometric_authenticator_provider.dart';
import 'package:starter/infrastructure/cache/cache_store.dart';
import 'package:starter/infrastructure/devtools/inspector_host.dart';
import 'package:starter/infrastructure/error_reporting/crash_reporter.dart';
import 'package:starter/infrastructure/firebase/firebase_performance_route_observer.dart';
import 'package:starter/infrastructure/haptics/haptic_service.dart';
import 'package:starter/infrastructure/media/media_picker.dart';
import 'package:starter/infrastructure/permissions/permission_service.dart';
import 'package:starter/infrastructure/platform/platform_capabilities.dart';
import 'package:starter/infrastructure/platform/system_ui_controller.dart';
import 'package:starter/infrastructure/secure_storage/secure_store_provider.dart';
import 'package:starter/infrastructure/sharing/share_service.dart';
import 'package:starter/infrastructure/updates/app_update_service.dart';
import 'package:starter/shared/adaptive/app_presentation_policy.dart';
import 'package:starter/shared/adaptive/app_unit.dart';
import 'package:starter/shared/motion/app_motion.dart';
import 'package:starter/shared/motion/app_page_transitions.dart';
import 'package:starter/shared/theme/forui_theme_factory.dart';

class App extends StatelessWidget {
  const App({
    required this.config,
    required this.dependencies,
    this.initialLocation,
    super.key,
  });

  final AppConfig config;
  final AppDependencies dependencies;
  final String? initialLocation;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(dependencies.settings.settingsRepository),
        initialSettingsProvider.overrideWithValue(dependencies.settings.initialSettings),
        settingsStoreProvider.overrideWithValue(dependencies.settings.settingsStore),
        secureStoreProvider.overrideWithValue(dependencies.storage.secureStore),
        crashReporterProvider.overrideWithValue(dependencies.telemetry.crashReporter),
        crashReporterBackendProvider.overrideWithValue(
          dependencies.telemetry.crashReporterBackend,
        ),
        versionGateStoreProvider.overrideWithValue(dependencies.remoteConfig.versionGateStore),
        // Precomputed in createApplication so the redirect reads a ready
        // AsyncData and the check never re-fires on rebuild.
        versionCheckProvider.overrideWith((ref) async => dependencies.remoteConfig.versionCheck),
        connectivityServiceProvider.overrideWithValue(
          dependencies.platform.connectivityService,
        ),
        appStartupResultProvider.overrideWith((ref) => dependencies.appStartupResult),
        initialDismissedAnnouncementIdsProvider.overrideWithValue(
          dependencies.initialDismissedAnnouncementIds,
        ),
        appBuildInfoProvider.overrideWithValue(dependencies.platform.buildInfo),
        authRepositoryProvider.overrideWithValue(dependencies.auth.authRepository),
        sessionRepositoryProvider.overrideWithValue(dependencies.auth.sessionRepository),
        initialSessionProvider.overrideWithValue(dependencies.auth.initialSession),
        analyticsClientProvider.overrideWithValue(dependencies.telemetry.analyticsClient),
        analyticsClientBackendProvider.overrideWithValue(
          dependencies.telemetry.analyticsClientBackend,
        ),
        initialAnalyticsOptInProvider.overrideWithValue(
          dependencies.telemetry.initialAnalyticsOptIn,
        ),
        featureFlagsSourceProvider.overrideWithValue(
          dependencies.remoteConfig.featureFlagsSource,
        ),
        biometricAuthenticatorProvider.overrideWithValue(
          dependencies.auth.biometricAuthenticator,
        ),
        attemptTrackerProvider.overrideWithValue(dependencies.auth.attemptTracker),
        // Every port provider throws StateError until overridden here.
        hapticServiceProvider.overrideWithValue(dependencies.platform.hapticService),
        otpRepositoryProvider.overrideWithValue(dependencies.auth.otpRepository),
        profileRepositoryProvider.overrideWithValue(dependencies.auth.profileRepository),
        notificationsRepositoryProvider.overrideWithValue(
          dependencies.notifications.notificationsRepository,
        ),
        notificationsBackendProvider.overrideWithValue(
          dependencies.notifications.notificationsBackend,
        ),
        initialNotificationPermissionProvider.overrideWithValue(
          dependencies.notifications.initialNotificationPermission,
        ),
        initialNotificationTokenProvider.overrideWithValue(
          dependencies.notifications.initialNotificationToken,
        ),
        permissionServiceProvider.overrideWithValue(dependencies.platform.permissionService),
        mediaPickerProvider.overrideWithValue(dependencies.platform.mediaPicker),
        shareServiceProvider.overrideWithValue(dependencies.platform.shareService),
        appUpdateServiceProvider.overrideWithValue(dependencies.platform.appUpdateService),
        appLinkHandlerProvider.overrideWithValue(dependencies.platform.appLinkHandler),
        experimentSourceProvider.overrideWithValue(dependencies.remoteConfig.experimentSource),
        cacheStoreProvider.overrideWithValue(dependencies.storage.cacheStore),
        feedbackTransportProvider.overrideWithValue(dependencies.feedback.feedbackTransport),
        initialFeedbackDraftProvider.overrideWithValue(dependencies.feedback.initialFeedbackDraft),
        initialFeedbackShakeEnabledProvider.overrideWithValue(
          dependencies.feedback.initialFeedbackShakeEnabled,
        ),
        feedbackAppMetadataProvider.overrideWithValue(dependencies.feedback.feedbackAppMetadata),
        // Reads live settings state so user preferences drive AutoLockController
        // directly; the feature defaults both to 0/false (inert) until wired here.
        autoLockDelaySecondsProvider.overrideWith(
          (ref) => ref.watch(settingsControllerProvider).autoLockDelaySeconds,
        ),
        lockOnBackgroundProvider.overrideWith(
          (ref) => ref.watch(settingsControllerProvider).lockOnBackground,
        ),
        platformCapabilitiesProvider.overrideWithValue(dependencies.platform.platformCapabilities),
      ],
      child: TranslationProvider(
        child: _AppView(
          key: ValueKey((config.environment, config.developmentToolsEnabled, initialLocation)),
          config: config,
          initialLocation: initialLocation,
          inspectorHost: dependencies.inspectorHost,
        ),
      ),
    );
  }
}

class _AppView extends ConsumerStatefulWidget {
  const _AppView({
    required this.config,
    required this.inspectorHost,
    this.initialLocation,
    super.key,
  });

  final AppConfig config;
  final String? initialLocation;

  /// Dev-only HTTP inspector host; the stub exposes no navigator observers so
  /// no dev tooling is wired in production/release/no-backend builds.
  final InspectorHost inspectorHost;

  @override
  ConsumerState<_AppView> createState() => _AppViewState();
}

class _AppViewState extends ConsumerState<_AppView> with WidgetsBindingObserver {
  late final GoRouter _router = buildAppRouter(
    config: widget.config,
    // Explicit initialLocation (tests, deep links) bypasses the splash.
    initialLocation: widget.initialLocation ?? AppRoutes.splashPath,
    // Fallback for harnesses that build the router without a ProviderScope;
    // the redirect itself reads live settingsControllerProvider state.
    hasCompletedOnboarding: ref.read(initialSettingsProvider).hasCompletedOnboarding,
    observers: [
      AnalyticsRouteObserver(client: ref.read(analyticsClientProvider)),
      LastRouteObserver(store: ref.read(settingsStoreProvider)),
      FirebasePerformanceRouteObserver(),
      ...widget.inspectorHost.navigatorObservers,
    ],
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Post-frame so the freshly created ProviderScope is used. On the
    // no-backend default, hydration surfaces AuthException.notConnected and
    // stays anonymous; the redirect reads live controller state so navigation
    // reacts the moment it resolves.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(sessionControllerProvider.notifier).hydrateFromSecureStore());
      _drainNotificationTapQueue();
      _listenAppLinkStream();
      // On a cold-start deep link, go_router can evaluate the redirect before
      // the version-check future resolves, missing the update-blocker on the
      // first pass; refresh once it resolves so the redirect re-runs.
      ref.listenManual(
        versionCheckProvider,
        (_, _) => _router.refresh(),
      );
    });
  }

  void _drainNotificationTapQueue() {
    final notifier = ref.read(notificationTapQueueProvider.notifier);
    ref.listenManual<List<NotificationTap>>(
      notificationTapQueueProvider,
      (previous, next) {
        if (next.isEmpty) return;
        for (final tap in next) {
          _dispatchNotificationTap(tap);
          notifier.consume(tap);
        }
      },
    );
    final initialPending = ref.read(notificationTapQueueProvider);
    for (final tap in initialPending) {
      _dispatchNotificationTap(tap);
      notifier.consume(tap);
    }
  }

  void _dispatchNotificationTap(NotificationTap tap) {
    if (!mounted) return;
    final target = tap.targetRoute;
    if (target.isEmpty) return;
    unawaited(_router.pushNamed(target, pathParameters: tap.params));
  }

  void _listenAppLinkStream() {
    // Handles foreground links; the cold-start initial link is captured in
    // createApplication and threaded as initialLocation instead.
    ref.listenManual<AsyncValue<ResolvedLink>>(
      appLinkStreamProvider,
      (previous, next) {
        final link = next.value;
        if (link == null) return;
        _dispatchAppLink(link);
      },
    );
  }

  void _dispatchAppLink(ResolvedLink link) {
    if (!mounted) return;
    _router.goNamed(
      link.routeName,
      pathParameters: link.pathParameters,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _router.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref.read(appLifecyclePhaseProvider.notifier).transitionTo(state);
    // BiometricUnlockController relocks on pause; refresh on resume so the
    // redirect re-sends the user to /lock instead of the prior protected shell.
    if (state == AppLifecycleState.resumed) {
      _router.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final presentationPolicy = ref.watch(presentationPolicyProvider);
    final interactionPolicy = presentationPolicy.interactionPolicy;
    final pageTransitionsTheme = presentationPolicy.isTenFoot
        ? televisionPageTransitionsTheme
        : nativePageTransitionsTheme;
    final localeData = TranslationProvider.of(context);
    final lightTheme = ForuiThemeFactory.build(
      brightness: Brightness.light,
      accent: settings.accent,
      fontScale: settings.fontScale,
      fontFamily: settings.fontFamily,
      interactionPolicy: interactionPolicy,
      presentationPolicy: presentationPolicy,
    );
    final darkTheme = ForuiThemeFactory.build(
      brightness: Brightness.dark,
      accent: settings.accent,
      fontScale: settings.fontScale,
      fontFamily: settings.fontFamily,
      interactionPolicy: interactionPolicy,
      presentationPolicy: presentationPolicy,
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => context.t.app.name,
      // Must stay constant across releases: changing it invalidates every
      // user's restorable draft state on upgrade.
      restorationScopeId: 'app',
      routerConfig: _router,
      locale: localeData.flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: FLocalizations.localizationsDelegates,
      theme: lightTheme.toApproximateMaterialTheme().copyWith(
        pageTransitionsTheme: pageTransitionsTheme,
      ),
      darkTheme: darkTheme.toApproximateMaterialTheme().copyWith(
        pageTransitionsTheme: pageTransitionsTheme,
      ),
      themeMode: _materialThemeMode(settings.themeMode),
      builder: (context, child) {
        final activeTheme = ForuiThemeFactory.build(
          brightness: Theme.of(context).brightness,
          accent: settings.accent,
          fontScale: settings.fontScale,
          fontFamily: settings.fontFamily,
          interactionPolicy: interactionPolicy,
          responsiveFontScale: context.appUnit.typographyScale,
          presentationPolicy: presentationPolicy,
        );

        // Flips status/navigation bar icons with the active brightness + accent.
        // Synchronous (SystemChrome.setSystemUIOverlayStyle is synchronous) and
        // idempotent; desktop/web short-circuit inside the controller.
        SystemUiController.applyOverlayStyle(
          brightness: Theme.of(context).brightness,
          accent: settings.accent,
          capabilities: PlatformCapabilities.current(),
        );

        return AppPresentationScope(
          policy: presentationPolicy,
          child: Theme(
            data: activeTheme.toApproximateMaterialTheme().copyWith(
              pageTransitionsTheme: pageTransitionsTheme,
            ),
            child: AppInputObserver(
              child: FTheme(
                data: activeTheme,
                accessibility: _tvAccessibility(presentationPolicy),
                motion: const FThemeMotion(
                  duration: AppMotion.standard,
                  curve: AppMotion.standardCurve,
                ),
                child: AppPresentationViewport(
                  child: AppKeyboardHost(
                    interactionPolicy: interactionPolicy,
                    bindings: [
                      AppKeyboardBinding(
                        activator: const SingleActivator(
                          LogicalKeyboardKey.backspace,
                          meta: true,
                          includeRepeats: false,
                        ),
                        onInvoke: _navigateBack,
                      ),
                    ],
                    child: Shortcuts(
                      debugLabel: 'TV Back/Menu aliases',
                      shortcuts: const <ShortcutActivator, Intent>{
                        SingleActivator(
                          LogicalKeyboardKey.goBack,
                          includeRepeats: false,
                        ): _RouterBackIntent(),
                        SingleActivator(
                          LogicalKeyboardKey.gameButtonB,
                          includeRepeats: false,
                        ): _RouterBackIntent(),
                      },
                      child: Actions(
                        actions: <Type, Action<Intent>>{
                          _RouterBackIntent: _RouterBackAction(),
                        },
                        child: FToaster(
                          child: FTooltipGroup(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Router content is the overlay base so each page's own
                                // SafeArea clears the status bar normally; banners below
                                // float over its top edge with no space reserved.
                                Positioned.fill(
                                  child: Builder(
                                    builder: (sheetContext) => ShakeFeedbackTrigger(
                                      // Off on web/desktop: no accelerometer, so the
                                      // sensors_plus factory throws and this disables honestly.
                                      enabled:
                                          ref.watch(feedbackShakeEnabledControllerProvider) &&
                                          !PlatformCapabilities.current().isWeb,
                                      onShake: ({required magnitude}) =>
                                          unawaited(showFeedbackSheet(context: sheetContext)),
                                      // Postpones idle auto-lock on activity; extend() and
                                      // this guard are both no-ops when the delay is <= 0.
                                      child: Listener(
                                        behavior: HitTestBehavior.translucent,
                                        onPointerDown: (_) => _maybeExtendAutoLock(),
                                        onPointerMove: (_) => _maybeExtendAutoLock(),
                                        onPointerSignal: (_) => _maybeExtendAutoLock(),
                                        child: child ?? const SizedBox.shrink(),
                                      ),
                                    ),
                                  ),
                                ),
                                // Connectivity first => topmost ("offline wins over any
                                // announcement"); both animate their own height so the
                                // Column collapses any hidden banner.
                                const Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ConnectivityBanner(),
                                      AnnouncementBanner(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  bool _navigateBack() {
    if (!_router.canPop()) {
      return false;
    }
    _router.pop();
    return true;
  }

  /// Postpones the idle auto-lock on any pointer activity. No-op when idle
  /// locking is disabled (delay <= 0), so the default install is inert.
  void _maybeExtendAutoLock() {
    if (ref.read(autoLockDelaySecondsProvider) > 0) {
      ref.read(autoLockControllerProvider.notifier).extend();
    }
  }
}

final class _RouterBackIntent extends Intent {
  const _RouterBackIntent();
}

final class _RouterBackAction extends ContextAction<_RouterBackIntent> {
  @override
  bool isEnabled(_RouterBackIntent intent, [BuildContext? context]) {
    if (context == null) {
      return false;
    }
    final routeContext = FocusManager.instance.primaryFocus?.context ?? context;
    return (Navigator.maybeOf(routeContext)?.canPop() ?? false) ||
        ModalRoute.of(routeContext)?.popDisposition == RoutePopDisposition.doNotPop;
  }

  @override
  Object? invoke(_RouterBackIntent intent, [BuildContext? context]) {
    final routeContext = FocusManager.instance.primaryFocus?.context ?? context!;
    unawaited(Navigator.of(routeContext).maybePop());
    return null;
  }
}

FAccessibility? _tvAccessibility(AppPresentationPolicy policy) {
  if (!policy.usesDirectionalFocus) {
    return null;
  }

  final features = WidgetsBinding.instance.platformDispatcher.accessibilityFeatures;
  return FAccessibility(
    accessibleNavigation: features.accessibleNavigation,
    motion: features.disableAnimations
        ? FAccessibilityMotion.disabled
        : features.reduceMotion
        ? FAccessibilityMotion.reduced
        : FAccessibilityMotion.all,
    focusHighlight: true,
  );
}

ThemeMode _materialThemeMode(AppThemeMode themeMode) {
  return switch (themeMode) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
  };
}
