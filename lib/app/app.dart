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
        settingsRepositoryProvider.overrideWithValue(dependencies.settingsRepository),
        initialSettingsProvider.overrideWithValue(dependencies.initialSettings),
        settingsStoreProvider.overrideWithValue(dependencies.settingsStore),
        secureStoreProvider.overrideWithValue(dependencies.secureStore),
        crashReporterProvider.overrideWithValue(dependencies.crashReporter),
        crashReporterBackendProvider.overrideWithValue(dependencies.crashReporterBackend),
        versionGateStoreProvider.overrideWithValue(dependencies.versionGateStore),
        // Precomputed in createApplication so the redirect reads a ready
        // AsyncData and the check never re-fires on rebuild (C5).
        versionCheckProvider.overrideWith((ref) async => dependencies.versionCheck),
        connectivityServiceProvider.overrideWithValue(dependencies.connectivityService),
        // Forward the AppStartupResult that createApplication already produced
        // (build-info + settings load + locale apply). SplashPage is the sole
        // consumer; it watches the future and hands off without re-loading any
        // of these (FutureProvider accepts FutureOr<T>, so a resolved value is
        // fine). Mirrors the settingsStoreProvider/versionCheckProvider shape.
        appStartupResultProvider.overrideWith((ref) => dependencies.appStartupResult),
        // Announcements: cold-start dismissed-id seed + installed build info,
        // both pre-loaded in AppDependencies.production so the controller
        // resolves synchronously on the first frame. Without the dismissed
        // override dismissals persist but never re-read on next launch.
        initialDismissedAnnouncementIdsProvider.overrideWithValue(
          dependencies.initialDismissedAnnouncementIds,
        ),
        appBuildInfoProvider.overrideWithValue(dependencies.buildInfo),
        // Wave-4 ports: each override is a peer of the existing port overrides
        // above. The composition root (AppDependencies) selected the no-backend
        // default for every one of these; a consumer swaps in a real adapter
        // only when credentials/an endpoint are configured.
        authRepositoryProvider.overrideWithValue(dependencies.authRepository),
        sessionRepositoryProvider.overrideWithValue(dependencies.sessionRepository),
        initialSessionProvider.overrideWithValue(dependencies.initialSession),
        analyticsClientProvider.overrideWithValue(dependencies.analyticsClient),
        analyticsClientBackendProvider.overrideWithValue(dependencies.analyticsClientBackend),
        initialAnalyticsOptInProvider.overrideWithValue(dependencies.initialAnalyticsOptIn),
        featureFlagsSourceProvider.overrideWithValue(dependencies.featureFlagsSource),
        biometricAuthenticatorProvider.overrideWithValue(dependencies.biometricAuthenticator),
        attemptTrackerProvider.overrideWithValue(dependencies.attemptTracker),
        // Haptic feedback port (Wave-5a). Peer of the other port overrides;
        // the composition root selected DeviceHapticService (prod) or
        // NoopHapticService (inMemory). The provider throws StateError until
        // this override is present (HARD RULE 2).
        hapticServiceProvider.overrideWithValue(dependencies.hapticService),
        // Wave-5b ports. Each is a peer of the existing port overrides; the
        // composition root selected the no-backend default for every one of
        // these. A consumer swaps in a real adapter only when credentials / an
        // endpoint / a platform capability is configured.
        otpRepositoryProvider.overrideWithValue(dependencies.otpRepository),
        // Profile port (Wave). Peer of the auth/otp port overrides; the
        // composition root selected the no-backend Noop default or the real
        // HttpProfileRepository when a backend URL is configured. The provider
        // throws StateError until this override is present (HARD RULE 2).
        profileRepositoryProvider.overrideWithValue(dependencies.profileRepository),
        notificationsRepositoryProvider.overrideWithValue(
          dependencies.notificationsRepository,
        ),
        notificationsBackendProvider.overrideWithValue(dependencies.notificationsBackend),
        initialNotificationPermissionProvider.overrideWithValue(
          dependencies.initialNotificationPermission,
        ),
        initialNotificationTokenProvider.overrideWithValue(
          dependencies.initialNotificationToken,
        ),
        permissionServiceProvider.overrideWithValue(dependencies.permissionService),
        mediaPickerProvider.overrideWithValue(dependencies.mediaPicker),
        shareServiceProvider.overrideWithValue(dependencies.shareService),
        appUpdateServiceProvider.overrideWithValue(dependencies.appUpdateService),
        // Deep-link service (Wave-5b). The composition root constructed the
        // production `AppLinksDeepLinkService` (or the no-op for unsupported
        // platforms / tests); `_AppViewState` ref.listens the resolved stream
        // and dispatches inbound links via context.goNamed / pushNamed.
        appLinkHandlerProvider.overrideWithValue(dependencies.appLinkHandler),
        // Wave-6 ports. Each is a peer of the existing port overrides; the
        // composition root selected the honest no-backend / real-local default
        // for every one of these (C2). A consumer swaps in a real adapter only
        // when credentials / an endpoint / a platform capability is configured.
        experimentSourceProvider.overrideWithValue(dependencies.experimentSource),
        cacheStoreProvider.overrideWithValue(dependencies.cacheStore),
        feedbackTransportProvider.overrideWithValue(dependencies.feedbackTransport),
        initialFeedbackDraftProvider.overrideWithValue(dependencies.initialFeedbackDraft),
        initialFeedbackShakeEnabledProvider.overrideWithValue(
          dependencies.initialFeedbackShakeEnabled,
        ),
        feedbackAppMetadataProvider.overrideWithValue(dependencies.feedbackAppMetadata),
        // pin-autolock seams: the auto-lock subsystem reads the idle delay +
        // background toggle through these two providers (the feature file
        // defaults both to 0/false so it is inert until wired here). Overridden
        // to read the live settings state so the user's preferences drive the
        // AutoLockController directly (single source of truth = SettingsState).
        autoLockDelaySecondsProvider.overrideWith(
          (ref) => ref.watch(settingsControllerProvider).autoLockDelaySeconds,
        ),
        lockOnBackgroundProvider.overrideWith(
          (ref) => ref.watch(settingsControllerProvider).lockOnBackground,
        ),
        platformCapabilitiesProvider.overrideWithValue(dependencies.platformCapabilities),
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

  /// Dev-only HTTP inspector host. Its navigator observers are attached to the
  /// router so the inspector dashboard can push onto the navigator when the host
  /// is active (development + dev tools + backend). The stub host exposes no
  /// observers, so no dev tooling is wired in production / release / no-backend.
  final InspectorHost inspectorHost;

  @override
  ConsumerState<_AppView> createState() => _AppViewState();
}

class _AppViewState extends ConsumerState<_AppView> with WidgetsBindingObserver {
  late final GoRouter _router = buildAppRouter(
    config: widget.config,
    // Cold start shows the in-app splash first; SplashPage hands off to home
    // (or onboarding, via the existing C5 redirect) the moment the startup
    // future resolves. Callers that pass an explicit initialLocation (tests,
    // deep links) bypass the splash as intended.
    initialLocation: widget.initialLocation ?? AppRoutes.splashPath,
    // Cold-start seed for the onboarding redirect. The redirect itself reads
    // LIVE settingsControllerProvider state so the in-session Skip path is
    // observable on the same tick; this seed is the fallback used by harnesses
    // that build the router without a ProviderScope above MaterialApp.router.
    hasCompletedOnboarding: ref.read(initialSettingsProvider).hasCompletedOnboarding,
    // Analytics plugs into the GoRouter via the single observers: seam (C4:
    // zero per-page edits). The observer emits a ScreenView on every route
    // change; its track() call is fire-and-forget and never throws, so
    // navigation is never gated on analytics.
    // The LastRouteObserver persists the latest restorable route path to
    // SettingsStore (state-restoration) fire-and-forget — it never blocks
    // navigation and never overrides the C5 redirect chain (the saved path is
    // only a cold-start initialLocation fallback, weaker than every gate).
    observers: [
      AnalyticsRouteObserver(client: ref.read(analyticsClientProvider)),
      LastRouteObserver(store: ref.read(settingsStoreProvider)),
      // Firebase Performance Monitoring: records a per-route Trace. Added
      // unconditionally; it self-no-ops on unsupported hosts (macOS / Linux /
      // Windows) and wraps every Firebase call in try/on Object, so it never
      // affects navigation or the desktop test / integration flows.
      FirebasePerformanceRouteObserver(),
      // Dev-only: spread the inspector host's navigator observers so its
      // dashboard can push onto the router's navigator when the host is active
      // (development + dev tools + backend only). The stub host exposes an empty
      // list, so no dev tooling is ever wired in a release graph.
      ...widget.inspectorHost.navigatorObservers,
    ],
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Cold-start session hydration: read any persisted refresh token from
    // SecureStore and, if present, ask the auth repository to mint a fresh
    // session. Fire-and-forget on the post-frame so the freshly created
    // ProviderScope is used. With the no-backend default this surfaces
    // AuthException.notConnected and stays anonymous (never fakes). The
    // redirect reads LIVE controller state, so the moment hydration resolves
    // the session flips and subsequent navigations observe it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(sessionControllerProvider.notifier).hydrateFromSecureStore());
      // Push-notifications foreground tap drain + deep-link stream wiring
      // (Wave-5b). Both subscribe on the post-frame so the freshly created
      // ProviderScope is used; both fire-and-forget their navigation side
      // effects. `ref.listenManual` is the Riverpod 3 API for subscribing
      // outside a `build` method (the auto-dispose variant would close the
      // subscription on the next build; we own the subscription lifetime).
      _drainNotificationTapQueue();
      _listenAppLinkStream();
      // Re-evaluate the C5 redirect the moment the version check resolves.
      // On a cold-start deep link, go_router evaluates the redirect
      // synchronously before the FutureProvider has produced a value, so the
      // HARD update-blocker block can be missed on the first evaluation.
      // Refreshing here ensures the redirect re-runs with the resolved
      // requirement (HARD wins over everything per the update-blocker spec).
      ref.listenManual(
        versionCheckProvider,
        (_, _) => _router.refresh(),
      );
    });
  }

  void _drainNotificationTapQueue() {
    // Drain any cold-start taps buffered before the router mounted, then keep
    // listening for foreground taps. A tap resolves to an existing named route
    // via context.pushNamed (the spec: never a raw URI). The queue is a
    // `List<NotificationTap>` value exposed by `NotificationTapQueue`; we
    // consume each dispatched tap through the notifier so the state stays in
    // sync.
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
    // Resolve to an existing named route via pushNamed. Params carry the
    // typed route arguments; the router rejects unknown names safely.
    unawaited(_router.pushNamed(target, pathParameters: tap.params));
  }

  void _listenAppLinkStream() {
    // Deep links: dispatch every resolved inbound URI to its named route via
    // context.goNamed (foreground links). The cold-start initial link is
    // captured in createApplication and threaded as initialLocation — this
    // stream handles everything AFTER the router mounts.
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
    // Resolve to an existing named route. The AppLinkHandler already rejected
    // foreign hosts and unknown paths; this only fires for trusted, known
    // destinations.
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
    // Re-evaluate the C5 redirect after a background -> foreground transition.
    // The BiometricUnlockController relocks on the paused edge; on resume the
    // redirect must fire again so the user is sent to /lock when biometric is
    // enabled and the subsystem is Locked. Without this the user returns to
    // the protected shell they were viewing before backgrounding, bypassing
    // the gate.
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
      // State-restoration: a CONSTANT restoration scope id so the
      // RestorationMixin pages (login/register/forgot/otp/reset/onboarding/
      // update-profile) participate under one stable scope. This id MUST stay
      // constant across releases — changing it invalidates every user's
      // restorable draft state on upgrade (passwords are never restored).
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

        // Reactive system bars (system-ui): track the active brightness + accent
        // so status / navigation bar icons flip with the ForUI theme. Synchronous
        // by design — SystemChrome.setSystemUIOverlayStyle is itself synchronous
        // — so no `await`/`unawaited` wrapper is needed in build. Idempotent.
        // Desktop/web short-circuit inside the controller; navigation is never
        // gated (this is a config command with no success/failure surface).
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
                            child: ConnectivityBanner(
                              // AnnouncementBanner mounts ONCE above the router child so
                              // auth/onboarding top-level routes (outside AppShell) see
                              // it. ConnectivityBanner stays topmost (offline wins over
                              // any announcement for the user's attention).
                              child: AnnouncementBanner(
                                // Shake-to-feedback (feedback feature): mounts once above
                                // the router so the listener is alive on every route.
                                // Gated by the user's shake opt-in (default off) AND
                                // !isWeb (web/desktop have no accelerometer -> the
                                // sensors_plus factory throws and the trigger disables
                                // honestly). onShake opens the modal feedback sheet; the
                                // Builder captures a context below the Navigator so the
                                // sheet's overlay resolves correctly.
                                child: Builder(
                                  builder: (sheetContext) => ShakeFeedbackTrigger(
                                    enabled:
                                        ref.watch(feedbackShakeEnabledControllerProvider) &&
                                        !PlatformCapabilities.current().isWeb,
                                    onShake: ({required magnitude}) =>
                                        unawaited(showFeedbackSheet(context: sheetContext)),
                                    // Idle auto-lock (pin-autolock) is inactivity-based.
                                    // Any pointer activity (tap / drag / scroll) on the
                                    // router's page content postpones the lockout by
                                    // restarting the idle timer via extend(). Gated on a
                                    // positive delay so the no-op default (idle locking
                                    // disabled) never builds a timer; extend() is itself
                                    // a no-op for delay <= 0, this guard keeps the read
                                    // inert when the feature is off.
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
