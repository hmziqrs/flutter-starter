import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/dependencies.dart';
import 'package:starter/app/interaction_policy_controller.dart';
import 'package:starter/app/keyboard/app_keyboard_host.dart';
import 'package:starter/app/platform_capabilities_provider.dart';
import 'package:starter/app/presentation/app_presentation_viewport.dart';
import 'package:starter/app/presentation_policy_controller.dart';
import 'package:starter/app/routing/app_router.dart';
import 'package:starter/features/settings/settings_controller.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/i18n/translations.g.dart';
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
        platformCapabilitiesProvider.overrideWithValue(dependencies.platformCapabilities),
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

class _AppViewState extends ConsumerState<_AppView> {
  late final GoRouter _router = buildAppRouter(
    config: widget.config,
    initialLocation: widget.initialLocation ?? '/',
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
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
      interactionPolicy: interactionPolicy,
      presentationPolicy: presentationPolicy,
    );
    final darkTheme = ForuiThemeFactory.build(
      brightness: Brightness.dark,
      accent: settings.accent,
      fontScale: settings.fontScale,
      interactionPolicy: interactionPolicy,
      presentationPolicy: presentationPolicy,
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => context.t.app.name,
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
          interactionPolicy: interactionPolicy,
          responsiveFontScale: context.appUnit.typographyScale,
          presentationPolicy: presentationPolicy,
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
