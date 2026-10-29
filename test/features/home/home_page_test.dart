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
import 'package:starter/shared/widgets/brand/app_icon_tile.dart';
import 'package:starter/shared/widgets/brand/app_ring_marker.dart';
import 'package:starter/shared/widgets/brand/app_status_tag.dart';

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

  testWidgets('renders the page intro: 24 w500 title with one muted summary line', (tester) async {
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

    final intro = find.byKey(const ValueKey('home-greeting'));
    expect(intro, findsOneWidget);
    expect(find.text('Welcome, Alex'), findsOneWidget);
    expect(
      find.text('Your starter is set up and ready for the next real feature.'),
      findsOneWidget,
    );
    final title = tester.widget<Text>(find.text('Welcome, Alex'));
    final summary = tester.widget<Text>(
      find.text('Your starter is set up and ready for the next real feature.'),
    );
    expect(title.style?.fontWeight, FontWeight.w500);
    expect(summary.style?.color, isNot(title.style?.color));
  });

  testWidgets('quick actions are outline cards with brand icon tiles and no fill', (tester) async {
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

    expect(find.byType(FTappable), findsNWidgets(4));
    for (final action in const ['profile', 'pricing', 'settings', 'login']) {
      final card = find.byKey(ValueKey('home-open-$action'));
      expect(
        find.descendant(of: card, matching: find.byType(AppIconTile)),
        findsOneWidget,
      );
      // Brand surfaces in the page are outlines (BRAND.md s8/s9): a line, no
      // grey or colored fill at rest — the card and its tile both.
      final decorations = tester
          .widgetList<DecoratedBox>(find.descendant(of: card, matching: find.byType(DecoratedBox)))
          .map((box) => box.decoration)
          .whereType<ShapeDecoration>()
          .toList();
      expect(decorations, isNotEmpty);
      for (final decoration in decorations) {
        expect(decoration.color, anyOf(isNull, Colors.transparent));
      }
      // The icon tile's own surface is the kit's 36px outline tile: circular
      // 8px corners (brand CSS arcs), fg/10 line at rest.
      final tileDecoration = decorations.where((d) {
        final shape = d.shape;
        return shape is RoundedRectangleBorder && shape.borderRadius == BorderRadius.circular(8);
      }).toList();
      expect(tileDecoration, isNotEmpty);
    }
  });

  testWidgets('quick action cards carry a muted one-liner under each label', (tester) async {
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

    const actions = <(String, String, String)>[
      ('home-open-profile', 'Update profile', 'Change your display name and avatar.'),
      ('home-open-pricing', 'View pricing', 'Compare the static plans side by side.'),
      ('home-open-settings', 'Open settings', 'Tune appearance, language, and account.'),
      ('home-open-login', 'Try the login flow', 'Walk through the example sign-in.'),
    ];
    for (final (actionKey, label, hint) in actions) {
      final card = find.byKey(ValueKey(actionKey));
      final labelText = tester.widget<Text>(
        find.descendant(of: card, matching: find.text(label)),
      );
      final hintText = tester.widget<Text>(
        find.descendant(of: card, matching: find.text(hint)),
      );
      // APP-BLOCKS: labels run 14 w500, their one-liner 14 muted — quieter
      // than the label, and clamped so long locale text cannot grow the card.
      expect(labelText.style?.fontWeight, FontWeight.w500);
      expect(hintText.style?.color, isNot(labelText.style?.color));
      expect(hintText.maxLines, 2);
    }
  });

  testWidgets('status renders soft role pills, live marker only on the ready state', (
    tester,
  ) async {
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

    expect(find.byType(AppStatusTag), findsNWidgets(3));
    final readyTag = tester.widget<AppStatusTag>(
      find.descendant(
        of: find.byKey(const ValueKey('home-status-ready')),
        matching: find.byType(AppStatusTag),
      ),
    );
    expect(readyTag.role, AppStatusRole.success);
    expect(readyTag.showMarker, isTrue);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-status-ready')),
        matching: find.byType(AppRingMarker),
      ),
      findsOneWidget,
    );
    final adaptiveTag = tester.widget<AppStatusTag>(
      find.descendant(
        of: find.byKey(const ValueKey('home-status-adaptive')),
        matching: find.byType(AppStatusTag),
      ),
    );
    expect(adaptiveTag.role, AppStatusRole.info);
    expect(adaptiveTag.showMarker, isFalse);
    // No display cards remain in the status section: the pill plus one muted
    // line is the whole item.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-status-ready')),
        matching: find.byType(FCard),
      ),
      findsNothing,
    );
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

  testWidgets('recent activity reads as ring-marker bullets, filled only when done', (
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
    await tester.pump();

    final readyMarker = tester.widget<AppRingMarker>(
      find.descendant(
        of: find.byKey(const ValueKey('home-activity-foundation-ready')),
        matching: find.byType(AppRingMarker),
      ),
    );
    expect(readyMarker.filled, isTrue);
    final adaptiveMarker = tester.widget<AppRingMarker>(
      find.descendant(
        of: find.byKey(const ValueKey('home-activity-adaptive-connected')),
        matching: find.byType(AppRingMarker),
      ),
    );
    expect(adaptiveMarker.filled, isFalse);
    // A quiet list, not tiles: no card chrome on the rows.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-activity-foundation-ready')),
        matching: find.byType(FTile),
      ),
      findsNothing,
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
