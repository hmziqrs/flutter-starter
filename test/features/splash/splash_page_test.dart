import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/splash/app_startup_result.dart';
import 'package:starter/features/splash/app_startup_result_provider.dart';
import 'package:starter/features/splash/splash_page.dart';
import 'package:starter/features/splash/splash_view_data.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;

Future<void> _pumpFrames(WidgetTester tester) async {
  for (var frame = 0; frame < 8; frame += 1) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Widget _harness({
  required Future<AppStartupResult> future,
  required void Function(AppStartupResult result) onComplete,
  bool disableAnimations = false,
}) {
  return ProviderScope(
    overrides: [
      appStartupResultProvider.overrideWith((ref) => future),
    ],
    child: TranslationProvider(
      child: Builder(
        builder: (context) {
          final localeData = TranslationProvider.of(context);
          final theme = generated.lightTheme;
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: localeData.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: FLocalizations.localizationsDelegates,
            theme: theme.toApproximateMaterialTheme(),
            builder: (context, child) {
              final content = FTheme(
                data: theme,
                child: FToaster(
                  child: FTooltipGroup(child: child ?? const SizedBox.shrink()),
                ),
              );
              if (!disableAnimations) {
                return content;
              }
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: content,
              );
            },
            home: SplashPage(onComplete: onComplete),
          );
        },
      ),
    ),
  );
}

const _successResult = AppStartupResult(
  buildInfo: AppBuildInfo(version: '1.2.3', buildNumber: '4'),
  settingsLoaded: true,
  localeApplied: true,
);

Widget _sceneHarness(SplashViewData viewData) {
  return TranslationProvider(
    child: Builder(
      builder: (context) {
        final localeData = TranslationProvider.of(context);
        final theme = generated.lightTheme;
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
          home: SplashScene(viewData: viewData),
        );
      },
    ),
  );
}

void main() {
  final en = AppLocale.en.buildSync();

  testWidgets('renders the tagline and app name while loading', (tester) async {
    final completer = Completer<AppStartupResult>();
    await tester.pumpWidget(
      _harness(future: completer.future, onComplete: (_) {}),
    );
    await _pumpFrames(tester);

    expect(find.text(en.splash.tagline), findsOneWidget);
    expect(find.text(en.app.name), findsOneWidget);
  });

  testWidgets('fires onComplete when the startup future resolves (no pumpAndSettle)', (
    tester,
  ) async {
    AppStartupResult? captured;
    var callCount = 0;
    await tester.pumpWidget(
      _harness(
        future: Future<AppStartupResult>.value(_successResult),
        onComplete: (result) {
          captured = result;
          callCount += 1;
        },
      ),
    );
    await _pumpFrames(tester);

    expect(captured, _successResult);
    await _pumpFrames(tester);
    expect(callCount, 1);
  });

  testWidgets('error phase renders the startup-error styling from a fixture', (
    tester,
  ) async {
    await tester.pumpWidget(_sceneHarness(SplashFixtures.error));
    await _pumpFrames(tester);

    expect(find.text(en.splash.error), findsOneWidget);
    expect(
      find.text(en.startupFailure.diagnosticId(id: 'STARTUP-UNKNOWN')),
      findsOneWidget,
    );
  });

  testWidgets('done phase renders the resolved build label', (tester) async {
    await tester.pumpWidget(_sceneHarness(SplashFixtures.done));
    await _pumpFrames(tester);

    expect(find.text('1.0.0+1'), findsOneWidget);
  });

  testWidgets('reduce-motion still completes handoff without waiting on the reveal', (
    tester,
  ) async {
    AppStartupResult? captured;
    await tester.pumpWidget(
      _harness(
        future: Future<AppStartupResult>.value(_successResult),
        onComplete: (result) => captured = result,
        disableAnimations: true,
      ),
    );
    await _pumpFrames(tester);

    expect(captured, _successResult);
  });

  testWidgets('reduce-motion loading phase shows the static loading label', (tester) async {
    final completer = Completer<AppStartupResult>();
    await tester.pumpWidget(
      _harness(
        future: completer.future,
        onComplete: (_) {},
        disableAnimations: true,
      ),
    );
    await _pumpFrames(tester);

    expect(find.text(en.splash.loading), findsOneWidget);
  });
}
