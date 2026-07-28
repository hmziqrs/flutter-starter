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
      // The initial route push already emitted a screen view for 'home'.
      client.clear();

      router.goNamed('settings');
      await _pumpFrames(tester);

      // Exactly one ScreenView, carrying the named route's name (go_router
      // resolves route.settings.name to `state.name ?? state.path`).
      final screenViews = client.events.whereType<ScreenView>().toList();
      expect(screenViews, hasLength(1));
      expect(screenViews.single.routeName, 'settings');
    });
  });
}

/// Pumps a bounded number of frames (the observer fires synchronously during
/// navigation, but routes settle over a few frames). Mirrors the integration
/// helper without importing `integration_test/`. Never uses `pumpAndSettle`.
Future<void> _pumpFrames(WidgetTester tester) async {
  for (var frame = 0; frame < 8; frame += 1) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Minimal concrete [Route] exposing a configurable [RouteSettings.name]. Lets
/// the direct-callback tests drive the observer without a Navigator or widget
/// tree. Uses [MaterialPageRoute] (fully concrete) so no abstract members are
/// left unimplemented.
class _NamedRoute extends MaterialPageRoute<void> {
  _NamedRoute(String? name)
    : super(
        settings: RouteSettings(name: name),
        builder: (_) => const SizedBox.shrink(),
      );
}
