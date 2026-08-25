import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/app/app_lifecycle_controller.dart';
import 'package:starter/app/shell/app_banner_host.dart';
import 'package:starter/features/announcements/announcement_fixtures.dart';
import 'package:starter/features/announcements/announcement_view_data.dart';
import 'package:starter/features/announcements/announcements_controller.dart';
import 'package:starter/features/connectivity/connectivity_controller.dart';
import 'package:starter/features/connectivity/connectivity_state.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;

import '../../infrastructure/connectivity/fake_connectivity_service.dart';

const ValueKey<String> _topChromeKey = ValueKey<String>('top-chrome-action');

Future<void> _pumpFrames(WidgetTester tester) async {
  for (var frame = 0; frame < 8; frame += 1) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// A page whose only affordance sits flush against the top edge, mirroring the
/// paywall's skip action.
Widget _topEdgePage(VoidCallback onPressed) {
  return Column(
    children: [
      Align(
        alignment: AlignmentDirectional.centerEnd,
        child: TextButton(
          key: _topChromeKey,
          onPressed: onPressed,
          child: const Text('skip'),
        ),
      ),
      const Expanded(child: SizedBox.shrink()),
    ],
  );
}

Widget _harness({
  required FakeConnectivityService service,
  required Widget child,
  List<Announcement> announcements = const <Announcement>[],
  EdgeInsets viewPadding = EdgeInsets.zero,
}) {
  return ProviderScope(
    overrides: [
      connectivityServiceProvider.overrideWithValue(service),
      appLifecyclePhaseProvider.overrideWith(AppLifecycleController.new),
      announcementsFixturesProvider.overrideWithValue(announcements),
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
            builder: (context, routerChild) => MediaQuery(
              data: MediaQuery.of(context).copyWith(padding: viewPadding),
              child: FTheme(
                data: theme,
                child: FToaster(
                  child: FTooltipGroup(
                    child: AppBannerHost(
                      child: routerChild ?? const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),
            home: Scaffold(body: child),
          );
        },
      ),
    ),
  );
}

void main() {
  testWidgets('keeps top-edge page chrome tappable while the offline banner shows', (
    tester,
  ) async {
    final service = FakeConnectivityService();
    var taps = 0;
    await tester.pumpWidget(
      _harness(service: service, child: _topEdgePage(() => taps += 1)),
    );
    await _pumpFrames(tester);

    service.emit(ConnectivityState.offline);
    await _pumpFrames(tester);
    expect(find.text(t.connectivity.offline), findsOneWidget);

    expect(
      find.byKey(_topChromeKey).hitTestable(),
      findsOneWidget,
      reason: 'the banner must inset the page, never paint over its top chrome',
    );
    await tester.tap(find.byKey(_topChromeKey).hitTestable());
    await _pumpFrames(tester);

    expect(taps, 1);
  });

  testWidgets('keeps top-edge page chrome tappable while an announcement shows', (tester) async {
    final service = FakeConnectivityService();
    var taps = 0;
    await tester.pumpWidget(
      _harness(
        service: service,
        announcements: [AnnouncementFixtures.welcome],
        child: _topEdgePage(() => taps += 1),
      ),
    );
    await _pumpFrames(tester);
    expect(find.text(t.announcements.fixtures.welcome.title), findsOneWidget);

    await tester.tap(find.byKey(_topChromeKey).hitTestable());
    await _pumpFrames(tester);

    expect(taps, 1);
  });

  testWidgets('pushes page content below the banner instead of overlapping it', (tester) async {
    final service = FakeConnectivityService();
    await tester.pumpWidget(
      _harness(service: service, child: _topEdgePage(() {})),
    );
    await _pumpFrames(tester);
    final withoutBanner = tester.getTopLeft(find.byKey(_topChromeKey)).dy;

    service.emit(ConnectivityState.offline);
    await _pumpFrames(tester);
    final withBanner = tester.getTopLeft(find.byKey(_topChromeKey)).dy;

    expect(withBanner, greaterThan(withoutBanner));
    expect(
      withBanner,
      greaterThanOrEqualTo(tester.getBottomLeft(find.text(t.connectivity.offline)).dy),
    );
  });

  testWidgets('does not inset the page twice for the top view padding', (tester) async {
    final service = FakeConnectivityService();
    const topPadding = 44.0;
    await tester.pumpWidget(
      _harness(
        service: service,
        viewPadding: const EdgeInsets.only(top: topPadding),
        child: _topEdgePage(() {}),
      ),
    );
    await _pumpFrames(tester);

    service.emit(ConnectivityState.offline);
    await _pumpFrames(tester);

    final bannerBottom = tester.getBottomLeft(find.text(t.connectivity.offline)).dy;
    final contentTop = tester.getTopLeft(find.byKey(_topChromeKey)).dy;

    expect(
      contentTop - bannerBottom,
      lessThan(topPadding),
      reason: 'the banner already consumed the top inset; the page must not add it again',
    );
  });
}
