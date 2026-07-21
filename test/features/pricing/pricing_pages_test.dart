import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/pricing/paywall_page.dart';
import 'package:starter/features/pricing/plan_view_data.dart';
import 'package:starter/features/pricing/pricing_page.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/adaptive/app_layout_class.dart';
import 'package:starter/shared/adaptive/app_layout_provider.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));

  testWidgets('pricing selects billing and a plan through its typed callback', (tester) async {
    final plans = PricingFixtures.standard(AppLocale.en.buildSync());
    PlanViewData? selectedPlan;
    BillingPeriod? selectedBilling;
    var terms = 0;
    var privacy = 0;

    await tester.pumpWidget(
      _FeatureTestApp(
        child: PricingPage(
          plans: plans,
          initialPlanId: PlanIds.basic,
          onSelectPlan: (plan, billing) {
            selectedPlan = plan;
            selectedBilling = billing;
          },
          onOpenTerms: () => terms += 1,
          onOpenPrivacy: () => privacy += 1,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('billing-annual')));
    await tester.ensureVisible(find.byKey(const ValueKey('select-plan-pro')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('select-plan-pro')));
    await tester.pumpAndSettle();

    expect(selectedPlan?.id, PlanIds.pro);
    expect(selectedBilling, BillingPeriod.annual);

    await tester.ensureVisible(find.byKey(const ValueKey('pricing-terms')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pricing-terms')));
    await tester.tap(find.byKey(const ValueKey('pricing-privacy')));
    await tester.pumpAndSettle();
    expect((terms, privacy), (1, 1));
  });

  testWidgets('pricing renders its compact, medium, and expanded layouts', (tester) async {
    final plans = PricingFixtures.standard(AppLocale.en.buildSync());
    _setViewport(tester, const Size(390, 844));

    for (final layoutClass in AppLayoutClass.values) {
      tester.view.physicalSize = switch (layoutClass) {
        AppLayoutClass.compact => const Size(390, 844),
        AppLayoutClass.medium => const Size(800, 844),
        AppLayoutClass.expanded => const Size(1200, 844),
      };
      await tester.pumpWidget(
        _FeatureTestApp(
          layoutClass: layoutClass,
          child: PricingPage(
            plans: plans,
            onSelectPlan: (_, _) {},
            onOpenTerms: () {},
            onOpenPrivacy: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(ValueKey('pricing-layout-${layoutClass.name}')), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('billing state survives an adaptive layout rebuild', (tester) async {
    final plans = PricingFixtures.standard(AppLocale.en.buildSync());
    final harnessKey = GlobalKey<_ResponsiveHarnessState>();
    BillingPeriod? selectedBilling;
    _setViewport(tester, const Size(390, 844));

    await tester.pumpWidget(
      _FeatureTestApp(
        child: _ResponsiveHarness(
          key: harnessKey,
          child: PricingPage(
            key: const ValueKey('retained-pricing'),
            plans: plans,
            onSelectPlan: (_, billing) => selectedBilling = billing,
            onOpenTerms: () {},
            onOpenPrivacy: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('billing-annual')));
    tester.view.physicalSize = const Size(1200, 844);
    harnessKey.currentState!.setLayout(AppLayoutClass.expanded);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('select-plan-team')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('select-plan-team')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('pricing-layout-expanded')), findsOneWidget);
    expect(selectedBilling, BillingPeriod.annual);
  });

  testWidgets('paywall keeps Skip visible and forwards honest feedback actions', (tester) async {
    _setViewport(tester, const Size(390, 844));
    final plans = PricingFixtures.standard(AppLocale.en.buildSync());
    var skips = 0;
    var restores = 0;
    var terms = 0;
    var privacy = 0;
    PlanViewData? continuedPlan;

    await tester.pumpWidget(
      _DirectFeatureTestApp(
        child: PaywallPage(
          plans: plans,
          initialBillingPeriod: BillingPeriod.annual,
          initialPlanId: PlanIds.pro,
          onSkip: () => skips += 1,
          onContinue: (plan, _) => continuedPlan = plan,
          onRestore: () => restores += 1,
          onOpenTerms: () => terms += 1,
          onOpenPrivacy: () => privacy += 1,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('paywall-skip')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('paywall-skip')));
    await tester.pumpAndSettle();

    for (final key in const [
      ValueKey('paywall-continue'),
      ValueKey('paywall-restore'),
      ValueKey('paywall-terms'),
      ValueKey('paywall-privacy'),
    ]) {
      await tester.ensureVisible(find.byKey(key));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.byKey(const ValueKey('paywall-skip')));
    await tester.pumpAndSettle();

    expect(skips, 2);
    expect(restores, 1);
    expect(terms, 1);
    expect(privacy, 1);
    expect(continuedPlan?.id, PlanIds.pro);
    expect(find.text('No payment or purchase will be made.'), findsOneWidget);
  });

  testWidgets('unavailable paywall disables selection and continue without disabling Skip', (
    tester,
  ) async {
    final plans = PricingFixtures.unavailable(AppLocale.en.buildSync());

    await tester.pumpWidget(
      _DirectFeatureTestApp(
        child: PaywallPage(
          plans: plans,
          availability: PricingAvailability.unavailable,
          onSkip: () {},
          onContinue: (_, _) {},
          onRestore: () {},
          onOpenTerms: () {},
          onOpenPrivacy: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.widget<FButton>(find.byKey(const ValueKey('paywall-continue'))).onPress, isNull);
    expect(tester.widget<FButton>(find.byKey(const ValueKey('paywall-skip'))).onPress, isNotNull);
    expect(tester.widget<FButton>(find.byKey(const ValueKey('select-plan-pro'))).onPress, isNull);
    expect(tester.widget<FButton>(find.byKey(const ValueKey('billing-monthly'))).onPress, isNull);
    expect(find.byKey(const ValueKey('paywall-unavailable')), findsOneWidget);
    expect(find.text('Unavailable'), findsNWidgets(3));
  });
}

class _FeatureTestApp extends StatelessWidget {
  const _FeatureTestApp({required this.child, this.layoutClass = AppLayoutClass.compact});

  final Widget child;
  final AppLayoutClass layoutClass;

  @override
  Widget build(BuildContext context) {
    final theme = generated.lightTheme;
    return TranslationProvider(
      child: ProviderScope(
        overrides: [appLayoutClassProvider.overrideWithValue(layoutClass)],
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
      ),
    );
  }
}

class _DirectFeatureTestApp extends StatelessWidget {
  const _DirectFeatureTestApp({required this.child});

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

class _ResponsiveHarness extends StatefulWidget {
  const _ResponsiveHarness({required this.child, super.key});

  final Widget child;

  @override
  State<_ResponsiveHarness> createState() => _ResponsiveHarnessState();
}

class _ResponsiveHarnessState extends State<_ResponsiveHarness> {
  AppLayoutClass _layoutClass = AppLayoutClass.compact;

  void setLayout(AppLayoutClass value) => setState(() => _layoutClass = value);

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [appLayoutClassProvider.overrideWithValue(_layoutClass)],
      child: widget.child,
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
