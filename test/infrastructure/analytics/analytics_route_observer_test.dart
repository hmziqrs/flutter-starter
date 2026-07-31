import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:starter/infrastructure/analytics/analytics_event.dart';
import 'package:starter/infrastructure/analytics/analytics_route_observer.dart';
import 'package:starter/infrastructure/analytics/recording_analytics_client.dart';

void main() {
  group('AnalyticsRouteObserver (direct callbacks)', () {
    test('didPush emits a single ScreenView with the route name', () {
      final client = RecordingAnalyticsClient();
      AnalyticsRouteObserver(client: client).didPush(_NamedRoute('home'), null);

      expect(client.events, hasLength(1));
      expect(client.events.single, const ScreenView(routeName: 'home'));
    });

    test('didReplace emits a ScreenView for the new route', () {
      final client = RecordingAnalyticsClient();
      AnalyticsRouteObserver(client: client).didReplace(
        newRoute: _NamedRoute('settings'),
        oldRoute: _NamedRoute('home'),
      );

      expect(client.events.single, const ScreenView(routeName: 'settings'));
    });

    test('didPop emits a ScreenView for the previous route (re-shown)', () {
      final client = RecordingAnalyticsClient();
      AnalyticsRouteObserver(client: client).didPop(
        _NamedRoute('settings'),
        _NamedRoute('home'),
      );

      expect(client.events.single, const ScreenView(routeName: 'home'));
    });

    test('skips anonymous routes with no name (no garbage emits)', () {
      final client = RecordingAnalyticsClient();
      AnalyticsRouteObserver(client: client)
        ..didPush(_NamedRoute(null), null)
        ..didPush(_NamedRoute(''), null);

      expect(client.events, isEmpty);
    });
  });

  group('AnalyticsRouteObserver (synthetic GoRouter)', () {
    testWidgets('emits a ScreenView carrying the GoRoute name on navigation', (
      tester,
    ) async {
      final client = RecordingAnalyticsClient();
      final observer = AnalyticsRouteObserver(client: client);
      final router = GoRouter(
        initialLocation: '/',
        observers: [observer],
        routes: [
          GoRoute(
            name: 'home',
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('home')),
          ),
          GoRoute(
            name: 'settings',
            path: '/settings',
            builder: (_, _) => const Scaffold(body: Text('settings')),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await _pumpFrames(tester);
      client.clear();

      router.goNamed('settings');
      await _pumpFrames(tester);

      final screenViews = client.events.whereType<ScreenView>().toList();
      expect(screenViews, hasLength(1));
      expect(screenViews.single.routeName, 'settings');
    });
  });
}

Future<void> _pumpFrames(WidgetTester tester) async {
  for (var frame = 0; frame < 8; frame += 1) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

class _NamedRoute extends MaterialPageRoute<void> {
  _NamedRoute(String? name)
    : super(
        settings: RouteSettings(name: name),
        builder: (_) => const SizedBox.shrink(),
      );
}
