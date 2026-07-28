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
import 'package:starter/app/routing/app_link_handler.dart';
import 'package:starter/app/routing/app_router.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/features/announcements/announcement_banner.dart';
import 'package:starter/features/announcements/announcements_controller.dart';
import 'package:starter/features/auth/auth_attempt_tracker.dart';
import 'package:starter/features/auth/otp_repository.dart';
import 'package:starter/features/connectivity/connectivity_banner.dart';
import 'package:starter/features/connectivity/connectivity_controller.dart';
import 'package:starter/features/feature_flags/feature_flags_source.dart';
import 'package:starter/features/force_update/version_gate_providers.dart';
import 'package:starter/features/notifications/notification_tap.dart';
import 'package:starter/features/notifications/notifications_controller.dart';
import 'package:starter/features/notifications/notifications_repository.dart';
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
import 'package:starter/infrastructure/error_reporting/crash_reporter.dart';
import 'package:starter/infrastructure/haptics/haptic_service.dart';
import 'package:starter/infrastructure/media/media_picker.dart';
import 'package:starter/infrastructure/permissions/permission_service.dart';
import 'package:starter/infrastructure/platform/platform_capabilities.dart';
import 'package:starter/infrastructure/platform/system_ui_controller.dart';
import 'package:starter/infrastructure/secure_storage/secure_store_provider.dart';
import 'package:starter/infrastructure/sharing/share_service.dart';
import 'package:starter/infrastructure/updates/app_update_service.dart';
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
      ],
      child: TranslationProvider(
        child: _AppView(
          key: ValueKey((config.environment, config.developmentToolsEnabled, initialLocation)),
          config: config,
          initialLocation: initialLocation,
        ),
      ),
    );
  }
}

class _AppView extends ConsumerStatefulWidget {
  const _AppView({required this.config, this.initialLocation, super.key});

  final AppConfig config;
  final String? initialLocation;

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
    observers: [AnalyticsRouteObserver(client: ref.read(analyticsClientProvider))],
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
    final interactionPolicy = ref.watch(interactionPolicyProvider);
    final localeData = TranslationProvider.of(context);
    final lightTheme = ForuiThemeFactory.build(
      brightness: Brightness.light,
      accent: settings.accent,
      fontScale: settings.fontScale,
      fontFamily: settings.fontFamily,
      interactionPolicy: interactionPolicy,
    );
    final darkTheme = ForuiThemeFactory.build(
      brightness: Brightness.dark,
      accent: settings.accent,
      fontScale: settings.fontScale,
      fontFamily: settings.fontFamily,
      interactionPolicy: interactionPolicy,
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => context.t.app.name,
      routerConfig: _router,
      locale: localeData.flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: FLocalizations.localizationsDelegates,
      theme: lightTheme.toApproximateMaterialTheme().copyWith(
        pageTransitionsTheme: nativePageTransitionsTheme,
      ),
      darkTheme: darkTheme.toApproximateMaterialTheme().copyWith(
        pageTransitionsTheme: nativePageTransitionsTheme,
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

        return Theme(
          data: activeTheme.toApproximateMaterialTheme().copyWith(
            pageTransitionsTheme: nativePageTransitionsTheme,
          ),
          child: AppInputObserver(
            child: FTheme(
              data: activeTheme,
              motion: const FThemeMotion(
                duration: AppMotion.standard,
                curve: AppMotion.standardCurve,
              ),
              child: AppKeyboardHost(
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
                child: FToaster(
                  child: FTooltipGroup(
                    child: ConnectivityBanner(
                      // AnnouncementBanner mounts ONCE above the router child so
                      // auth/onboarding top-level routes (outside AppShell) see
                      // it. ConnectivityBanner stays topmost (offline wins over
                      // any announcement for the user's attention).
                      child: AnnouncementBanner(
                        child: child ?? const SizedBox.shrink(),
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
}

ThemeMode _materialThemeMode(AppThemeMode themeMode) {
  return switch (themeMode) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
  };
}
