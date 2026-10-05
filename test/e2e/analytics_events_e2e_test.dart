import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/security/in_memory_secure_store.dart';
import 'package:starter/infrastructure/analytics/analytics_event.dart';
import 'package:starter/infrastructure/analytics/http_analytics_client.dart';
import 'package:starter/infrastructure/analytics/opt_in_gated_analytics_client.dart';

import '../infrastructure/hono_server_handle.dart';

/// Live analytics e2e: `screen_view` events flow through the real opt-in gate
/// and `HttpAnalyticsClient` batching onto `POST /v1/events` of the live JS
/// Hono server, asserted via its `GET /v1/events/last` inspection surface.
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
      final handle = await HonoServerHandle.start(runtime: runtime);
      server = handle;
      baseUri = handle.baseUri;
    });

    tearDownAll(() async {
      final handle = server;
      if (handle != null) await handle.close();
    });

    test('screen_view reaches the live server only after opt-in', () async {
      final store = InMemorySecureStore();
      final http = HttpAnalyticsClient(baseUrl: baseUri);
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
}

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
