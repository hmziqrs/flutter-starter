import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/home/home_controller.dart';
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
    expect(
      tester.getSize(find.byKey(const ValueKey('home-status-ready'))).height,
      lessThan(200),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps page content below the device safe area', (tester) async {
    const safePadding = EdgeInsets.only(top: 59, bottom: 34);
    await _pumpHome(
      tester,
      size: const Size(390, 844),
      safePadding: safePadding,
      page: HomePage(
        viewData: HomeViewData.defaults(),
        onOpenProfile: _noop,
        onOpenPricing: _noop,
        onOpenSettings: _noop,
        onOpenLogin: _noop,
      ),
    );

    expect(
      tester.getTopLeft(find.byKey(const ValueKey('home-greeting'))).dy,
      greaterThan(safePadding.top),
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('home-layout-compact'))).dy,
      safePadding.top,
    );
    expect(
      tester.getBottomRight(find.byKey(const ValueKey('home-layout-compact'))).dy,
      844,
    );
  });

  testWidgets('renders an honest empty activity variant', (tester) async {
    await _pumpHome(
      tester,
      size: const Size(390, 900),
      feedLoader: () async => const [],
      page: HomePage(
        viewData: HomeViewData.defaults(),
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

  testWidgets('the per-instance feed seam previews the empty activity state', (tester) async {
    // The dev-gallery home cases scope the feed through `HomePage.feedLoader`;
    // without any harness-level override the empty case must render empty.
    await _pumpHome(
      tester,
      size: const Size(390, 900),
      settle: false,
      page: HomePage(
        viewData: HomeViewData.emptyActivity(),
        feedLoader: () => Future.value(HomeViewData.emptyActivity().recentActivity),
        onOpenProfile: _noop,
        onOpenPricing: _noop,
        onOpenSettings: _noop,
        onOpenLogin: _noop,
      ),
    );

    // Bounded frames: the scoped feed resolves after the first frame.
    for (var frame = 0; frame < 4; frame += 1) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final empty = find.byKey(const ValueKey('home-activity-empty'));
    await tester.ensureVisible(empty);
    expect(empty, findsOneWidget);
    expect(find.byKey(const ValueKey('home-activity-list')), findsNothing);
    expect(find.byKey(const ValueKey('home-activity-skeleton')), findsNothing);
  });

  testWidgets('surfaces the error state view when the feed fails to compose', (tester) async {
    await _pumpHome(
      tester,
      size: const Size(390, 900),
      settle: false,
      // An `Error` (not an arbitrary exception) so Riverpod's default retry
      // policy skips its backoff and settles the feed into `AsyncError`.
      feedLoader: () async => throw StateError('feed failed'),
      page: HomePage(
        viewData: HomeViewData.defaults(),
        onOpenProfile: _noop,
        onOpenPricing: _noop,
        onOpenSettings: _noop,
        onOpenLogin: _noop,
      ),
    );

    // First frame: the feed future still pends, so bones mirror the tiles.
    expect(find.byKey(const ValueKey('home-activity-skeleton')), findsOneWidget);

    // Bounded frames until the failed compose settles into the error arm.
    for (var frame = 0; frame < 4; frame += 1) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final error = find.byKey(const ValueKey('home-activity-error'));
    await tester.ensureVisible(error);
    expect(error, findsOneWidget);
    expect(find.text('Could not load this'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-activity-list')), findsNothing);
    expect(find.byKey(const ValueKey('home-activity-skeleton')), findsNothing);
  });

  testWidgets('mirrors the recent-activity feed with skeleton bones before content', (
    tester,
  ) async {
    await _pumpHome(
      tester,
      size: const Size(390, 900),
      settle: false,
      page: HomePage(
        viewData: HomeViewData.defaults(),
        onOpenProfile: _noop,
        onOpenPricing: _noop,
        onOpenSettings: _noop,
        onOpenLogin: _noop,
      ),
    );

    // First frame: the feed is still composing, so bones mirror the tiles.
    expect(find.byKey(const ValueKey('home-activity-skeleton')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-activity-skeleton-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-activity-list')), findsNothing);

    await tester.pump();

    expect(find.byKey(const ValueKey('home-activity-skeleton')), findsNothing);
    expect(find.byKey(const ValueKey('home-activity-list')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('home-activity-foundation-ready')),
      findsOneWidget,
    );
  });

  testWidgets('pull-to-refresh holds the indicator, then completes with the notConnected toast', (
    tester,
  ) async {
    final reload = Completer<List<HomeActivityViewData>>();
    var loads = 0;
    await _pumpHome(
      tester,
      size: const Size(390, 900),
      feedLoader: () {
        loads += 1;
        return loads == 1 ? Future.value(HomeViewData.defaultActivity) : reload.future;
      },
      page: HomePage(
        viewData: HomeViewData.defaults(),
        onOpenProfile: _noop,
        onOpenPricing: _noop,
        onOpenSettings: _noop,
        onOpenLogin: _noop,
      ),
    );

    await tester.fling(
      find.byKey(const ValueKey('home-layout-compact')),
      const Offset(0, 350),
      1000,
    );
    // onRefresh starts after the show animation; bounded frames until it holds.
    for (var frame = 0; frame < 4; frame += 1) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // The refresh future is held open, so the accent indicator stays up.
    expect(loads, 2);
    expect(find.byType(RefreshProgressIndicator), findsOneWidget);

    reload.complete(HomeViewData.defaultActivity);
    await tester.pumpAndSettle();

    // Honest backend-free completion: indicator dismissed + notConnected toast.
    expect(find.byType(RefreshProgressIndicator), findsNothing);
    expect(find.text('This action is not connected yet.'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-activity-list')), findsOneWidget);
  });

  testWidgets('uses one repeated-item gap across status and activity sections', (tester) async {
    await _pumpHome(
      tester,
      size: const Size(390, 900),
      page: HomePage(
        viewData: HomeViewData.defaults(),
        onOpenProfile: _noop,
        onOpenPricing: _noop,
        onOpenSettings: _noop,
        onOpenLogin: _noop,
      ),
    );

    final statusGap =
        tester.getTopLeft(find.byKey(const ValueKey('home-status-adaptive'))).dy -
        tester.getBottomLeft(find.byKey(const ValueKey('home-status-ready'))).dy;
    final activityGap =
        tester.getTopLeft(find.byKey(const ValueKey('home-activity-adaptive-connected'))).dy -
        tester.getBottomLeft(find.byKey(const ValueKey('home-activity-foundation-ready'))).dy;

    expect(statusGap, activityGap);
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
  EdgeInsets safePadding = EdgeInsets.zero,
  bool settle = true,
  Future<List<HomeActivityViewData>> Function()? feedLoader,
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
            // FToaster hosts AppToast feedback, matching the app shell.
            child: FToaster(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final layoutClass = AppLayoutClass.fromWidth(
                    constraints.maxWidth,
                    compactMax: context.theme.breakpoints.sm,
                    expandedMin: context.theme.breakpoints.lg,
                  );
                  final content = ProviderScope(
                    overrides: [
                      appLayoutClassProvider.overrideWithValue(layoutClass),
                      if (feedLoader != null)
                        homeRecentActivityProvider.overrideWith((ref) => feedLoader()),
                    ],
                    child: child ?? const SizedBox.shrink(),
                  );
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      padding: safePadding,
                      viewPadding: safePadding,
                    ),
                    child: content,
                  );
                },
              ),
            ),
          );
        },
        home: page,
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  }
}

void _noop() {}
