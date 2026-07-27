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
import 'package:starter/app/routing/app_router.dart';
import 'package:starter/features/connectivity/connectivity_banner.dart';
import 'package:starter/features/connectivity/connectivity_controller.dart';
import 'package:starter/features/force_update/version_gate_providers.dart';
import 'package:starter/features/settings/settings_controller.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/features/settings/settings_store.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/error_reporting/crash_reporter.dart';
import 'package:starter/infrastructure/secure_storage/secure_store_provider.dart';
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
    initialLocation: widget.initialLocation ?? '/',
    // Cold-start seed for the onboarding redirect. The redirect itself reads
    // LIVE settingsControllerProvider state so the in-session Skip path is
    // observable on the same tick; this seed is the fallback used by harnesses
    // that build the router without a ProviderScope above MaterialApp.router.
    hasCompletedOnboarding: ref.read(initialSettingsProvider).hasCompletedOnboarding,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
      interactionPolicy: interactionPolicy,
    );
    final darkTheme = ForuiThemeFactory.build(
      brightness: Brightness.dark,
      accent: settings.accent,
      fontScale: settings.fontScale,
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
          interactionPolicy: interactionPolicy,
          responsiveFontScale: context.appUnit.typographyScale,
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
                      child: child ?? const SizedBox.shrink(),
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
