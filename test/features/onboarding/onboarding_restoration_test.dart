import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/onboarding/onboarding_page.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;

/// The same scope id the app root uses (`appRestorationScopeId` in
/// `lib/app/app.dart`); duplicated here so this suite exercises the page's
/// restoration machinery without importing the whole app shell.
const String _restorationScopeId = 'app';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));

  testWidgets('restores the page index after restartAndRestore', (tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final semantics = tester.ensureSemantics();

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

    expect(find.bySemanticsLabel('Step 1 of 3'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('onboarding-continue')));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    expect(find.bySemanticsLabel('Step 2 of 3'), findsOneWidget);

    await tester.restartAndRestore();
    await tester.pump();

    expect(find.bySemanticsLabel('Step 2 of 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('still builds with restoration disabled (no scope)', (tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final semantics = tester.ensureSemantics();

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

    expect(find.bySemanticsLabel('Step 1 of 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
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
        restorationScopeId: _restorationScopeId,
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
