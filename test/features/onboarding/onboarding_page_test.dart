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
    final semantics = tester.ensureSemantics();
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

    // Progress is announced by a live region, not painted as text.
    expect(find.bySemanticsLabel('Step 1 of 3'), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding-back')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('onboarding-continue')));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Step 2 of 3'), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding-back')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('onboarding-continue')));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Step 3 of 3'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('onboarding-continue')));
    expect(paywallOpens, 1);

    await tester.tap(find.byKey(const ValueKey('onboarding-back')));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Step 2 of 3'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('Skip is always available and invokes its callback', (tester) async {
    final semantics = tester.ensureSemantics();
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

    expect(find.bySemanticsLabel('Step 3 of 3'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('onboarding-skip')));
    await tester.pumpAndSettle();
    expect(skips, 1);
    semantics.dispose();
  });

  testWidgets('entry state focuses no action, so no ring is painted', (tester) async {
    _setViewport(tester, const Size(390, 844));

    await tester.pumpWidget(
      _FeatureTestApp(
        child: OnboardingPage(onSkip: () {}, onOpenPaywall: () {}),
      ),
    );
    await tester.pumpAndSettle();

    // Calm entry: nothing is focused at arrival, so neither skip nor the
    // primary action paints a focus ring before the visitor acts.
    final focusedButton = FocusManager.instance.primaryFocus?.context
        ?.findAncestorWidgetOfExactType<FButton>();
    expect(focusedButton, isNull);
  });

  testWidgets('back button is a line at rest in dark mode (no card fill)', (tester) async {
    _setViewport(tester, const Size(1200, 844));

    await tester.pumpWidget(
      _FeatureTestApp(
        theme: generated.darkTheme,
        child: OnboardingPage(initialPage: 1, onSkip: () {}, onOpenPaywall: () {}),
      ),
    );
    await tester.pumpAndSettle();

    final boxes = tester.widgetList<DecoratedBox>(
      find.descendant(
        of: find.byKey(const ValueKey('onboarding-back')),
        matching: find.byType(DecoratedBox),
      ),
    );
    expect(boxes, isNotEmpty);
    for (final box in boxes) {
      final decoration = box.decoration;
      if (decoration is ShapeDecoration) {
        // BRAND.md s9/s13: the outline button is a line at rest — the fill
        // ForUI's dark inherit paints (the #171717 card token) is stripped,
        // and the border line itself survives.
        expect(decoration.color, isNull);
        expect((decoration.shape as RoundedSuperellipseBorder).side, isNot(BorderSide.none));
      }
    }
  });

  testWidgets('current page survives compact to expanded resize rebuild', (tester) async {
    _setViewport(tester, const Size(390, 844));
    final semantics = tester.ensureSemantics();

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
    expect(find.bySemanticsLabel('Step 2 of 3'), findsOneWidget);

    tester.view.physicalSize = const Size(1200, 844);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('onboarding-layout-expanded')), findsOneWidget);
    expect(find.bySemanticsLabel('Step 2 of 3'), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding-slide-adaptive')), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}

class _FeatureTestApp extends StatelessWidget {
  const _FeatureTestApp({required this.child, this.theme});

  final Widget child;
  final FThemeData? theme;

  @override
  Widget build(BuildContext context) {
    final resolvedTheme = theme ?? generated.lightTheme;
    return TranslationProvider(
      child: MaterialApp(
        locale: AppLocale.en.flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: FLocalizations.localizationsDelegates,
        theme: resolvedTheme.toApproximateMaterialTheme(),
        builder: (context, materialChild) => FTheme(
          data: resolvedTheme,
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
