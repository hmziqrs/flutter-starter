import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:starter/app/app.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/config/app_environment.dart';
import 'package:starter/app/dependencies.dart';
import 'package:starter/app/dependencies/dependency_aggregates.dart';
import 'package:starter/app/routing/app_link_handler.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/features/security/in_memory_secure_store.dart';
import 'package:starter/infrastructure/analytics/analytics_client.dart';
import 'package:starter/infrastructure/analytics/analytics_event.dart';
import 'package:starter/infrastructure/analytics/composite_analytics_client.dart';
import 'package:starter/infrastructure/analytics/http_analytics_client.dart';
import 'package:starter/infrastructure/analytics/noop_analytics_client.dart';
import 'package:starter/infrastructure/analytics/opt_in_gated_analytics_client.dart';
import 'package:starter/infrastructure/error_reporting/crash_reporter.dart';
import 'package:starter/infrastructure/error_reporting/noop_crash_reporter.dart';
import 'package:starter/infrastructure/logging/app_logger.dart';

import '../app/support/pump_app_frames.dart';
import '../infrastructure/hono_server_handle.dart';

/// Live analytics e2e: `screen_view` events flow through the real opt-in gate
/// and `HttpAnalyticsClient` batching onto `POST /v1/events` of the live JS
/// Hono server, asserted via its `GET /v1/events/last` inspection surface.
/// The second case drives the full production chain — the pumped `App` wires
/// the `AnalyticsRouteObserver` into the router, which tracks through the
/// gated composite onto the live server.
void main() {
  final runtime = JsRuntime.resolve();

  group('analytics events e2e (HttpAnalyticsClient <-> live JS Hono)', () {
    if (runtime == null) {
      test(
        'skipped: no JS runtime (bun or npx tsx) available',
        () {},
        skip: 'no JS runtime (bun or npx tsx) available on PATH',
      );
      return;
    }

    HonoServerHandle? server;
    late final Uri baseUri;

    setUpAll(() async {
      // The `testWidgets` below eagerly installs the TestWidgetsFlutterBinding,
      // whose mock HttpOverrides global would fake-400 every socket in this
      // file (server health check included). runZoned(null) restores the real
      // network stack for the live-server surface.
      final handle = await _liveNetwork(() => HonoServerHandle.start(runtime: runtime));
      server = handle;
      baseUri = handle.baseUri;
    });

    tearDownAll(() async {
      final handle = server;
      if (handle != null) await handle.close();
    });

    test('screen_view reaches the live server only after opt-in', () async {
      await _liveNetwork(() async {
        final store = InMemorySecureStore();
        final http = HttpAnalyticsClient(baseUrl: baseUri);
        addTearDown(http.dispose);
        final gated = OptInGatedAnalyticsClient(delegate: http, secureStore: store);

        await gated.track(const ScreenView(routeName: 'pre-opt-in'));
        await http.flush();
        expect(
          [for (final event in await _retainedEvents(baseUri)) event['name']],
          isNot(contains('pre-opt-in')),
        );

        await store.write('analytics.opt_in', 'true');
        await gated.track(const ScreenView(routeName: 'home'));
        await gated.track(const ScreenView(routeName: 'settings'));
        await http.flush();

        final events = await _retainedEvents(baseUri);
        expect(
          [for (final event in events) event['name'] as String?],
          containsAllInOrder(<String>['home', 'settings']),
        );
        final home = events.firstWhere((event) => event['name'] == 'home');
        expect(home['type'], 'screen_view');
        expect(home['props'], isEmpty);
      });
    });

    testWidgets('router navigation tracks a screen_view per navigation', (tester) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final store = InMemorySecureStore();
      await store.write(analyticsOptInKey, 'true');
      final http = HttpAnalyticsClient(baseUrl: baseUri);
      await tester.pumpWidget(
        App(
          config: _developmentConfig,
          dependencies: AppDependencies.inMemory(
            secureStore: store,
            telemetry: TelemetryDependencies(
              crashReporter: const NoopCrashReporter(),
              crashReporterBackend: const NoopCrashReporterBackend(),
              // The production composite shape: the ungated Noop logger plus
              // every real backend behind the SecureStore opt-in gate.
              analyticsClient: CompositeAnalyticsClient(<AnalyticsClient>[
                NoopAnalyticsClient(logger: AppLogger.bootstrap()),
                OptInGatedAnalyticsClient(delegate: http, secureStore: store),
              ]),
              analyticsClientBackend: RemoteAnalyticsBackend(host: baseUri.host),
              initialAnalyticsOptIn: true,
            ),
          ),
        ),
      );
      await pumpAppFrames(tester);

      // Navigate via the router the production way: a UI tap through the home
      // page's callback-to-navigation wrapper, then a direct goNamed.
      final homeButton = find.byKey(const ValueKey('home-open-settings'));
      expect(homeButton, findsOneWidget, reason: 'the splash hands off to home');
      final router = GoRouter.of(tester.element(find.byType(Navigator).first));
      await tester.tap(homeButton);
      await pumpAppFrames(tester);
      router.goNamed(AppRoutes.pricing);
      await pumpAppFrames(tester);

      final events = await tester.runAsync(
        () => _liveNetwork(() async {
          await http.flush();
          return _retainedEvents(baseUri);
        }),
      );
      // The binding's pending-timer invariant runs before test-package
      // tearDowns, so the ticker's fake periodic timer must be cancelled
      // inside the body.
      http.dispose();
      final names = [for (final event in events ?? const <Map<String, Object?>>[]) event['name']];
      expect(names, containsAllInOrder(<String>['home', 'settings', 'pricing']));
      for (final event in events ?? const <Map<String, Object?>>[]) {
        expect(event['type'], 'screen_view');
      }
    });
  });
}

/// Runs [body] against the real network stack. The `testWidgets` case below
/// eagerly initializes the TestWidgetsFlutterBinding, whose mock
/// [HttpOverrides.global] fake-400s every socket in this suite (the server
/// health check included). The SDK exposes no getter for the previous global,
/// so this restores the file's pre-`testWidgets` condition instead: before any
/// `testWidgets` declaration existed, plain `test()`s never initialized the
/// binding and all sockets in this e2e were real. The binding installs its
/// mock exactly once (at init), so the null sticks for the suite.
Future<T> _liveNetwork<T>(Future<T> Function() body) {
  HttpOverrides.global = null;
  return body();
}

final _developmentConfig = AppConfig(
  environment: AppEnvironment.development,
  enableVerboseLogging: true,
  enableDevTools: true,
  iosAppleId: '',
  allowedDeepLinkHosts: AllowedDeepLinkHosts.empty,
);

Future<List<Map<String, Object?>>> _retainedEvents(Uri baseUri) async {
  final client = HttpClient();
  try {
    final response = await (await client.getUrl(
      Uri.parse('$baseUri/v1/events/last'),
    )).close();
    final decoded = jsonDecode(await utf8.decoder.bind(response).join());
    final events = decoded is Map<String, Object?> ? decoded['events'] : null;
    return events is List<Object?>
        ? events.cast<Map<String, Object?>>()
        : const <Map<String, Object?>>[];
  } finally {
    client.close(force: true);
  }
}
