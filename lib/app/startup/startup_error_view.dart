import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/config/app_environment.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/adaptive/app_interaction_policy.dart';
import 'package:starter/shared/theme/app_sizes.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/theme/forui_theme_factory.dart';

String startupDiagnosticIdFor(Object error) {
  return switch (error) {
    AppConfigException() || AppEnvironmentException() => 'STARTUP-CONFIG',
    _ => 'STARTUP-UNKNOWN',
  };
}

class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({required this.diagnosticId, this.onRetry, super.key});

  final String diagnosticId;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return TranslationProvider(
      child: _LocalizedStartupErrorApp(
        diagnosticId: diagnosticId,
        onRetry: onRetry,
      ),
    );
  }
}

class _LocalizedStartupErrorApp extends StatelessWidget {
  const _LocalizedStartupErrorApp({required this.diagnosticId, this.onRetry});

  final String diagnosticId;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final localeData = TranslationProvider.of(context);
    final theme = ForuiThemeFactory.build(
      brightness: Brightness.light,
      accent: AppAccent.neutral,
      fontScale: 1,
      interactionPolicy: AppInteractionPolicy.touch,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: localeData.flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: FLocalizations.localizationsDelegates,
      theme: theme.toApproximateMaterialTheme(),
      builder: (context, child) => FTheme(
        data: theme,
        child: FToaster(
          child: FTooltipGroup(
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
      home: StartupErrorView(
        diagnosticId: diagnosticId,
        onRetry: onRetry,
      ),
    );
  }
}

class StartupErrorView extends StatelessWidget {
  const StartupErrorView({required this.diagnosticId, this.onRetry, super.key});

  final String diagnosticId;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    return FScaffold(
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSizes.formContentMaxWidth),
            child: Padding(
              padding: AppSpacing.screenPadding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    FLucideIcons.triangleAlert,
                    size: 40,
                    color: context.theme.colors.error,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    translations.startupFailure.title,
                    style: context.theme.typography.display.xl,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    translations.startupFailure.body,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SelectableText(
                    translations.startupFailure.diagnosticId(id: diagnosticId),
                    key: const ValueKey('startup-diagnostic-id'),
                    textAlign: TextAlign.center,
                  ),
                  if (onRetry case final onRetry?) ...[
                    const SizedBox(height: AppSpacing.xl),
                    FButton(
                      key: const ValueKey('startup-retry'),
                      onPress: onRetry,
                      child: Text(translations.common.retry),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
