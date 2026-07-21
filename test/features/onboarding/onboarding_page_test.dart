import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/onboarding/onboarding_page.dart';
import 'package:starter/features/onboarding/onboarding_view_data.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));

  test('fixtures expose stable first, middle, and final slides', () {
    final slides = OnboardingFixtures.standard(AppLocale.en.buildSync());

    expect(slides, hasLength(3));
    expect(slides.map((slide) => slide.id), [
      OnboardingSlideIds.foundation,
      OnboardingSlideIds.adaptive,
      OnboardingSlideIds.preferences,
    ]);
  });

  test('initial page is validated from zero through two', () {
    expect(
      () => OnboardingPage(
        initialPage: -1,
        onSkip: () {},
        onOpenPaywall: () {},
      ),
      throwsAssertionError,
    );
    expect(
      () => OnboardingPage(
        initialPage: 3,
        onSkip: () {},
        onOpenPaywall: () {},
      ),
      throwsAssertionError,
    );
  });

  testWidgets('first, middle, and final pages provide local navigation', (tester) async {
    _setViewport(tester, const Size(390, 844));
    var paywallOpens = 0;

    await tester.pumpWidget(
      _FeatureTestApp(
        child: OnboardingPage(
          onSkip: () {},
          onOpenPaywall: () => paywallOpens += 1,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Step 1 of 3'), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding-back')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('onboarding-continue')));
    await tester.pumpAndSettle();
    expect(find.text('Step 2 of 3'), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding-back')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('onboarding-continue')));
    await tester.pumpAndSettle();
    expect(find.text('Step 3 of 3'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('onboarding-continue')));
    expect(paywallOpens, 1);

    await tester.tap(find.byKey(const ValueKey('onboarding-back')));
    await tester.pumpAndSettle();
    expect(find.text('Step 2 of 3'), findsOneWidget);
  });

  testWidgets('Skip is always available and invokes its callback', (tester) async {
    var skips = 0;

    await tester.pumpWidget(
      _FeatureTestApp(
        child: OnboardingPage(
          initialPage: 2,
          onSkip: () => skips += 1,
          onOpenPaywall: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Step 3 of 3'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('onboarding-skip')));
    await tester.pumpAndSettle();
    expect(skips, 1);
  });

  testWidgets('current page survives compact to expanded resize rebuild', (tester) async {
    _setViewport(tester, const Size(390, 844));

    await tester.pumpWidget(
      _FeatureTestApp(
        child: OnboardingPage(
          key: const ValueKey('retained-onboarding'),
          onSkip: () {},
          onOpenPaywall: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('onboarding-continue')));
    await tester.pumpAndSettle();
    expect(find.text('Step 2 of 3'), findsOneWidget);

    tester.view.physicalSize = const Size(1200, 844);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('onboarding-layout-expanded')), findsOneWidget);
    expect(find.text('Step 2 of 3'), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding-slide-adaptive')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FeatureTestApp extends StatelessWidget {
  const _FeatureTestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = generated.lightTheme;
    return TranslationProvider(
      child: MaterialApp(
        locale: AppLocale.en.flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: FLocalizations.localizationsDelegates,
        theme: theme.toApproximateMaterialTheme(),
        builder: (context, materialChild) => FTheme(
          data: theme,
          child: FToaster(child: materialChild ?? const SizedBox.shrink()),
        ),
        home: child,
      ),
    );
  }
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}
