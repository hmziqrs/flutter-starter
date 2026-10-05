import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:starter/app/app_lifecycle_controller.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/config/app_environment.dart';
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
import 'package:starter/app/shell/app_banner_host.dart';
import 'package:starter/features/announcements/announcement_fixtures.dart';
import 'package:starter/features/announcements/announcement_view_data.dart';
import 'package:starter/features/announcements/announcements_controller.dart';
import 'package:starter/features/auth/auth_attempt_tracker.dart';
import 'package:starter/features/auth/otp_repository.dart';
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
import 'package:starter/features/search/search_corpus.dart';
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
import 'package:starter/infrastructure/logging/app_logger.dart';
import 'package:starter/infrastructure/media/media_picker.dart';
import 'package:starter/infrastructure/permissions/permission_service.dart';
import 'package:starter/infrastructure/platform/platform_capabilities.dart';
import 'package:starter/infrastructure/platform/system_ui_controller.dart';
import 'package:starter/infrastructure/secure_storage/secure_store_provider.dart';
import 'package:starter/infrastructure/sharing/share_service.dart';
import 'package:starter/infrastructure/updates/app_update_service.dart';
import 'package:starter/shared/adaptive/app_interaction_policy.dart';
import 'package:starter/shared/adaptive/app_presentation_policy.dart';
import 'package:starter/shared/adaptive/app_unit.dart';
import 'package:starter/shared/motion/app_motion.dart';
import 'package:starter/shared/motion/app_page_transitions.dart';
import 'package:starter/shared/theme/forui_theme_factory.dart';

/// Restoration scope id of the root [MaterialApp.router].
///
/// Must stay constant and stable across releases — changing it invalidates
/// every user's restorable state on upgrade. Test harnesses that pump pages
/// inside their own `MaterialApp` must reference this constant (never a fresh
/// literal) so production and test restoration buckets cannot drift apart.
const String appRestorationScopeId = 'app';

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
        appLoggerProvider.overrideWithValue(dependencies.logger),
        settingsRepositoryProvider.overrideWithValue(dependencies.settings.settingsRepository),
        initialSettingsProvider.overrideWithValue(dependencies.settings.initialSettings),
        settingsStoreProvider.overrideWithValue(dependencies.settings.settingsStore),
        secureStoreProvider.overrideWithValue(dependencies.storage.secureStore),
        crashReporterProvider.overrideWithValue(dependencies.telemetry.crashReporter),
        crashReporterBackendProvider.overrideWithValue(
          dependencies.telemetry.crashReporterBackend,
        ),
        versionGateStoreProvider.overrideWithValue(dependencies.remoteConfig.versionGateStore),
        versionCheckProvider.overrideWith((ref) async => dependencies.remoteConfig.versionCheck),
        connectivityServiceProvider.overrideWithValue(
          dependencies.platform.connectivityService,
        ),
        appStartupResultProvider.overrideWith((ref) => dependencies.appStartupResult),
        initialDismissedAnnouncementIdsProvider.overrideWithValue(
          dependencies.initialDismissedAnnouncementIds,
        ),
        announcementsFixturesProvider.overrideWithValue(
          config.environment == AppEnvironment.development
              ? AnnouncementFixtures.standard
              : const <Announcement>[],
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
        searchCorpusSourceProvider.overrideWithValue(dependencies.searchCorpusSource),
        feedbackTransportProvider.overrideWithValue(dependencies.feedback.feedbackTransport),
        initialFeedbackDraftProvider.overrideWithValue(dependencies.feedback.initialFeedbackDraft),
        initialFeedbackShakeEnabledProvider.overrideWithValue(
          dependencies.feedback.initialFeedbackShakeEnabled,
        ),
        feedbackAppMetadataProvider.overrideWithValue(dependencies.feedback.feedbackAppMetadata),
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

  final InspectorHost inspectorHost;

  @override
  ConsumerState<_AppView> createState() => _AppViewState();
}

class _AppViewState extends ConsumerState<_AppView> with WidgetsBindingObserver {
  /// Key for the root navigator so route guards can present overlays (soft
  /// update dialog) from a context under it — the redirect context sits above
  /// the navigator.
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'app-root-navigator',
  );

  late final GoRouter _router = buildAppRouter(
    config: widget.config,
    initialLocation: widget.initialLocation ?? AppRoutes.splashPath,
    hasCompletedOnboarding: ref.read(initialSettingsProvider).hasCompletedOnboarding,
    navigatorKey: _navigatorKey,
    observers: [
      AnalyticsRouteObserver(client: ref.read(analyticsClientProvider)),
      LastRouteObserver(store: ref.read(settingsStoreProvider)),
      FirebasePerformanceRouteObserver(logger: ref.read(appLoggerProvider)),
      ...widget.inspectorHost.navigatorObservers,
    ],
  );

  static final _ForuiThemeMemo _lightThemeMemo = _ForuiThemeMemo();
  static final _ForuiThemeMemo _darkThemeMemo = _ForuiThemeMemo();
  static final _ForuiThemeMemo _activeThemeMemo = _ForuiThemeMemo();
  final _MaterialThemeMemo _lightMaterialThemeMemo = _MaterialThemeMemo();
  final _MaterialThemeMemo _darkMaterialThemeMemo = _MaterialThemeMemo();
  final _MaterialThemeMemo _activeMaterialThemeMemo = _MaterialThemeMemo();
  final Stopwatch _autoLockInteractionClock = Stopwatch()..start();
  Duration? _lastAutoLockExtendAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(sessionControllerProvider.notifier).hydrateFromSecureStore());
      _drainNotificationTapQueue();
      _listenAppLinkStream();
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
    if (state == AppLifecycleState.resumed) {
      _router.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeSettings = ref.watch(
      settingsControllerProvider.select(
        (settings) => (
          themeMode: settings.themeMode,
          accent: settings.accent,
          fontScale: settings.fontScale,
          spacingVariant: settings.spacingVariant,
          radiusVariant: settings.radiusVariant,
          fontFamily: settings.fontFamily,
        ),
      ),
    );
    final presentationPolicy = ref.watch(presentationPolicyProvider);
    final interactionPolicy = presentationPolicy.interactionPolicy;
    final pageTransitionsTheme = presentationPolicy.isTenFoot
        ? televisionPageTransitionsTheme
        : nativePageTransitionsTheme;
    final localeData = TranslationProvider.of(context);
    final materialThemeMode = _materialThemeMode(themeSettings.themeMode);
    final lightTheme = _lightThemeMemo.build(
      brightness: Brightness.light,
      accent: themeSettings.accent,
      fontScale: themeSettings.fontScale,
      fontFamily: themeSettings.fontFamily,
      interactionPolicy: interactionPolicy,
      spacingScaleFactor: themeSettings.spacingVariant.scaleFactor,
      radiusScaleFactor: themeSettings.radiusVariant.scaleFactor,
      presentationPolicy: presentationPolicy,
    );
    final darkTheme = materialThemeMode == ThemeMode.light
        ? null
        : _darkThemeMemo.build(
            brightness: Brightness.dark,
            accent: themeSettings.accent,
            fontScale: themeSettings.fontScale,
            fontFamily: themeSettings.fontFamily,
            interactionPolicy: interactionPolicy,
            spacingScaleFactor: themeSettings.spacingVariant.scaleFactor,
            radiusScaleFactor: themeSettings.radiusVariant.scaleFactor,
            presentationPolicy: presentationPolicy,
          );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => context.t.app.name,
      restorationScopeId: appRestorationScopeId,
      routerConfig: _router,
      locale: localeData.flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: FLocalizations.localizationsDelegates,
      theme: _lightMaterialThemeMemo.build(lightTheme, pageTransitionsTheme),
      darkTheme: darkTheme == null
          ? null
          : _darkMaterialThemeMemo.build(darkTheme, pageTransitionsTheme),
      themeMode: materialThemeMode,
      builder: (context, child) {
        final activeTheme = _activeThemeMemo.build(
          brightness: Theme.of(context).brightness,
          accent: themeSettings.accent,
          fontScale: themeSettings.fontScale,
          fontFamily: themeSettings.fontFamily,
          interactionPolicy: interactionPolicy,
          responsiveFontScale: context.appUnit.typographyScale,
          spacingScaleFactor: themeSettings.spacingVariant.scaleFactor,
          radiusScaleFactor: themeSettings.radiusVariant.scaleFactor,
          presentationPolicy: presentationPolicy,
        );

        SystemUiController.applyOverlayStyle(
          brightness: Theme.of(context).brightness,
          accent: themeSettings.accent,
          capabilities: PlatformCapabilities.current(),
        );

        return AppPresentationScope(
          policy: presentationPolicy,
          child: Theme(
            data: _activeMaterialThemeMemo.build(activeTheme, pageTransitionsTheme),
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
                            child: AppBannerHost(
                              child: Builder(
                                builder: (sheetContext) => ShakeFeedbackTrigger(
                                  enabled:
                                      ref.watch(feedbackShakeEnabledControllerProvider) &&
                                      !PlatformCapabilities.current().isWeb,
                                  onShake: ({required magnitude}) =>
                                      unawaited(showFeedbackSheet(context: sheetContext)),
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

  static const Duration _autoLockExtendWindow = Duration(milliseconds: 16);

  void _maybeExtendAutoLock() {
    if (ref.read(autoLockDelaySecondsProvider) <= 0) {
      return;
    }
    final elapsed = _autoLockInteractionClock.elapsed;
    final lastExtendAt = _lastAutoLockExtendAt;
    if (lastExtendAt != null && elapsed - lastExtendAt < _autoLockExtendWindow) {
      return;
    }
    _lastAutoLockExtendAt = elapsed;
    ref.read(autoLockControllerProvider.notifier).extend();
  }
}

typedef _ForuiThemeKey = ({
  Brightness brightness,
  AppAccent accent,
  double fontScale,
  AppInteractionPolicy interactionPolicy,
  String? fontFamily,
  double responsiveFontScale,
  double spacingScaleFactor,
  double radiusScaleFactor,
  AppPresentationPolicy? presentationPolicy,
});

final class _ForuiThemeMemo {
  _ForuiThemeKey? _key;
  late FThemeData _theme;

  FThemeData build({
    required Brightness brightness,
    required AppAccent accent,
    required double fontScale,
    required AppInteractionPolicy interactionPolicy,
    String? fontFamily,
    double responsiveFontScale = 1,
    double spacingScaleFactor = 1,
    double radiusScaleFactor = 1,
    AppPresentationPolicy? presentationPolicy,
  }) {
    final key = (
      brightness: brightness,
      accent: accent,
      fontScale: fontScale,
      interactionPolicy: interactionPolicy,
      fontFamily: fontFamily,
      responsiveFontScale: responsiveFontScale,
      spacingScaleFactor: spacingScaleFactor,
      radiusScaleFactor: radiusScaleFactor,
      presentationPolicy: presentationPolicy,
    );
    if (_key == key) {
      return _theme;
    }
    final theme = ForuiThemeFactory.build(
      brightness: brightness,
      accent: accent,
      fontScale: fontScale,
      fontFamily: fontFamily,
      interactionPolicy: interactionPolicy,
      responsiveFontScale: responsiveFontScale,
      spacingScaleFactor: spacingScaleFactor,
      radiusScaleFactor: radiusScaleFactor,
      presentationPolicy: presentationPolicy,
    );
    _key = key;
    _theme = theme;
    return theme;
  }
}

final class _MaterialThemeMemo {
  FThemeData? _data;
  PageTransitionsTheme? _pageTransitionsTheme;
  late ThemeData _theme;

  ThemeData build(FThemeData data, PageTransitionsTheme pageTransitionsTheme) {
    if (identical(_data, data) && identical(_pageTransitionsTheme, pageTransitionsTheme)) {
      return _theme;
    }
    final theme = data.toApproximateMaterialTheme().copyWith(
      pageTransitionsTheme: pageTransitionsTheme,
    );
    _data = data;
    _pageTransitionsTheme = pageTransitionsTheme;
    _theme = theme;
    return theme;
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
