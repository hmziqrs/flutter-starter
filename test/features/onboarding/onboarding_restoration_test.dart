import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/onboarding/onboarding_page.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;

/// State-restoration spec — the onboarding page index survives a simulated
/// process death via RestorationMixin (RestorableIntN) under the constant 'app'
/// restoration scope, so a user who left off mid-onboarding returns to the
/// same slide.
void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));

  testWidgets('restores the page index after restartAndRestore', (tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      _RestorationTestApp(
        home: OnboardingPage(
          onSkip: () {},
          onOpenPaywall: () {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Step 1 of 3'), findsOneWidget);

    // Advance to slide 2 (index 1) -> progress reads "Step 2 of 3".
    await tester.tap(find.byKey(const ValueKey('onboarding-continue')));
    // Pump bounded frames (never pumpAndSettle) to let the ForUI tap-feedback
    // timer and the AppMotion page transition complete so onPageChanged fires
    // and the restorable page index is updated before we capture state.
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    expect(find.text('Step 2 of 3'), findsOneWidget);

    // Simulate process death + relaunch with restoration data.
    await tester.restartAndRestore();
    await tester.pump();

    // The page index is restored: the user lands back on slide 2.
    expect(find.text('Step 2 of 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('still builds with restoration disabled (no scope)', (tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      _NoRestorationTestApp(
        home: OnboardingPage(
          onSkip: () {},
          onOpenPaywall: () {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Restores to the default initial page (0 -> "Step 1 of 3").
    expect(find.text('Step 1 of 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _RestorationTestApp extends StatelessWidget {
  const _RestorationTestApp({required this.home});

  final Widget home;

  @override
  Widget build(BuildContext context) {
    final theme = generated.lightTheme;
    return TranslationProvider(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        restorationScopeId: 'app',
        home: home,
        locale: AppLocale.en.flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: FLocalizations.localizationsDelegates,
        theme: theme.toApproximateMaterialTheme(),
        builder: (context, child) => FTheme(
          data: theme,
          child: FToaster(child: child ?? const SizedBox.shrink()),
        ),
      ),
    );
  }
}

class _NoRestorationTestApp extends StatelessWidget {
  const _NoRestorationTestApp({required this.home});

  final Widget home;

  @override
  Widget build(BuildContext context) {
    final theme = generated.lightTheme;
    return TranslationProvider(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: home,
        locale: AppLocale.en.flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: FLocalizations.localizationsDelegates,
        theme: theme.toApproximateMaterialTheme(),
        builder: (context, child) => FTheme(
          data: theme,
          child: FToaster(child: child ?? const SizedBox.shrink()),
        ),
      ),
    );
  }
}
