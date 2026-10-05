import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/infrastructure/analytics/analytics_event.dart';
import 'package:starter/infrastructure/analytics/http_analytics_client.dart';

void main() {
  late HttpServer server;
  final posted = <Map<String, Object?>>[];

  setUp(() async {
    posted.clear();
    final bound = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server = bound
      ..listen((request) async {
        final body = await utf8.decoder.bind(request).join();
        posted.add(jsonDecode(body) as Map<String, Object?>);
        request.response.statusCode = HttpStatus.noContent;
        await request.response.close();
      });
  });

  tearDown(() => server.close(force: true));

  List<Map<String, Object?>> eventsOf(int batch) =>
      (posted[batch]['events']! as List<Object?>).cast<Map<String, Object?>>();

  test('buffers below batchSize, then posts a contract-shaped batch', () async {
    final client = HttpAnalyticsClient(
      baseUrl: Uri.parse('http://127.0.0.1:${server.port}'),
      batchSize: 2,
    );

    await client.track(const ScreenView(routeName: 'home'));
    expect(posted, isEmpty, reason: 'a single event stays buffered');

    await client.track(const Tap(target: 'cta'));
    final events = eventsOf(0);
    expect(events, hasLength(2));
    expect(events[0]['type'], 'screen_view');
    expect(events[0]['name'], 'home');
    expect(events[0]['props'], isEmpty);
    expect(events[0]['ts'], isNotEmpty);
    expect(events[1]['type'], 'tap');
    expect(events[1]['name'], 'cta');
  });

  test('setUserId flushes the prior identity and tags later batches', () async {
    final client = HttpAnalyticsClient(
      baseUrl: Uri.parse('http://127.0.0.1:${server.port}'),
      batchSize: 2,
    );

    await client.setUserId('user-42');
    await client.track(const FunnelStep(name: 'signup', step: 3));
    await client.setUserId(null);
    await client.track(const ScreenView(routeName: 'settings'));
    await client.flush();

    expect(posted, hasLength(2));
    expect(eventsOf(0).single['type'], 'funnel_step');
    expect(eventsOf(0).single['props'], <String, Object?>{'step': 3});
    expect(posted[0]['userId'], 'user-42');
    expect(eventsOf(1).single['name'], 'settings');
    expect(posted[1].containsKey('userId'), isFalse);
  });

  test('an unreachable backend never throws', () async {
    final client = HttpAnalyticsClient(
      baseUrl: Uri.parse('http://127.0.0.1:1'),
      dio: Dio(
        BaseOptions(
          baseUrl: 'http://127.0.0.1:1',
          validateStatus: (_) => true,
          connectTimeout: const Duration(milliseconds: 300),
        ),
      ),
    );
    await client.track(const ScreenView(routeName: 'home'));
    await expectLater(client.flush(), completes);
  });
}
