import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/home/home_page.dart';
import 'package:starter/features/home/home_view_data.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/adaptive/app_interaction_policy.dart';
import 'package:starter/shared/adaptive/app_layout_class.dart';
import 'package:starter/shared/adaptive/app_layout_provider.dart';
import 'package:starter/shared/theme/forui_theme_factory.dart';

void main() {
  test('HomeViewData exposes immutable default and empty activity variants', () {
    final defaults = HomeViewData.defaults(greetingName: 'Sam');
    final empty = HomeViewData.emptyActivity(greetingName: 'Sam');

    expect(defaults.greetingName, 'Sam');
    expect(defaults.statuses, hasLength(3));
    expect(defaults.recentActivity, isNotEmpty);
    expect(empty.hasRecentActivity, isFalse);
    expect(
      () => defaults.statuses.add(
        const HomeStatusViewData(id: 'extra', kind: HomeStatusKind.ready),
      ),
      throwsUnsupportedError,
    );
  });

  testWidgets('quick actions invoke their explicit navigation callbacks', (tester) async {
    final calls = <String>[];
    await _pumpHome(
      tester,
      size: const Size(390, 900),
      page: HomePage(
        viewData: HomeViewData.defaults(),
        onOpenProfile: () => calls.add('profile'),
        onOpenPricing: () => calls.add('pricing'),
        onOpenSettings: () => calls.add('settings'),
        onOpenLogin: () => calls.add('login'),
      ),
    );

    for (final action in const ['profile', 'pricing', 'settings', 'login']) {
      final finder = find.byKey(ValueKey('home-open-$action'));
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    expect(calls, ['profile', 'pricing', 'settings', 'login']);
  });

  testWidgets('uses canonical one, two, and three column layouts', (tester) async {
    final page = HomePage(
      viewData: HomeViewData.defaults(),
      onOpenProfile: _noop,
      onOpenPricing: _noop,
      onOpenSettings: _noop,
      onOpenLogin: _noop,
    );

    await _pumpHome(tester, size: const Size(390, 900), page: page);
    expect(find.byKey(const ValueKey('home-layout-compact')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-status-grid-1')), findsOneWidget);

    tester.view.physicalSize = const Size(800, 900);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('home-layout-medium')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-status-grid-2')), findsOneWidget);

    tester.view.physicalSize = const Size(1200, 900);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('home-layout-expanded')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-status-grid-3')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders an honest empty activity variant', (tester) async {
    await _pumpHome(
      tester,
      size: const Size(390, 900),
      page: HomePage(
        viewData: HomeViewData.emptyActivity(),
        onOpenProfile: _noop,
        onOpenPricing: _noop,
        onOpenSettings: _noop,
        onOpenLogin: _noop,
      ),
    );

    final empty = find.byKey(const ValueKey('home-activity-empty'));
    await tester.ensureVisible(empty);
    expect(empty, findsOneWidget);
    expect(find.text('Nothing here yet'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-activity-list')), findsNothing);
  });

  testWidgets('medium content remains usable after shell width is allocated', (tester) async {
    await _pumpHome(
      tester,
      size: const Size(712, 600),
      page: HomePage(
        viewData: HomeViewData.defaults(),
        onOpenProfile: _noop,
        onOpenPricing: _noop,
        onOpenSettings: _noop,
        onOpenLogin: _noop,
      ),
    );

    expect(find.byKey(const ValueKey('home-layout-medium')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('home-open-login')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpHome(
  WidgetTester tester, {
  required Size size,
  required HomePage page,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await LocaleSettings.setLocale(AppLocale.en);

  final theme = ForuiThemeFactory.build(
    brightness: Brightness.light,
    accent: AppAccent.neutral,
    fontScale: 1,
    interactionPolicy: AppInteractionPolicy.touch,
  );
  await tester.pumpWidget(
    TranslationProvider(
      child: MaterialApp(
        locale: AppLocale.en.flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: FLocalizations.localizationsDelegates,
        theme: theme.toApproximateMaterialTheme(),
        builder: (context, child) {
          return FTheme(
            data: theme,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final layoutClass = AppLayoutClass.fromWidth(
                  constraints.maxWidth,
                  compactMax: context.theme.breakpoints.sm,
                  expandedMin: context.theme.breakpoints.lg,
                );
                return ProviderScope(
                  overrides: [appLayoutClassProvider.overrideWithValue(layoutClass)],
                  child: child ?? const SizedBox.shrink(),
                );
              },
            ),
          );
        },
        home: page,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _noop() {}
