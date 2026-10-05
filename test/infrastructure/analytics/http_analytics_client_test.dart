import 'dart:async';
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

  test('a flush ticker tick uploads buffered events below batchSize', () async {
    final ticks = StreamController<void>();
    addTearDown(ticks.close);
    final client = HttpAnalyticsClient(
      baseUrl: Uri.parse('http://127.0.0.1:${server.port}'),
      flushTicker: (_) => ticks.stream,
    );
    addTearDown(client.dispose);

    await client.track(const ScreenView(routeName: 'home'));
    await client.track(const ScreenView(routeName: 'settings'));
    expect(posted, isEmpty, reason: 'two events stay buffered below batchSize 20');

    ticks.add(null);
    await _pollUntilPosted(posted);

    expect(posted, hasLength(1), reason: 'the tick flushes one batch');
    final events = eventsOf(0);
    expect([for (final event in events) event['name']], <String>['home', 'settings']);
    for (final event in events) {
      expect(event['type'], 'screen_view');
    }
  });

  test('a flush ticker tick with an empty buffer posts nothing', () async {
    final ticks = StreamController<void>();
    addTearDown(ticks.close);
    final client = HttpAnalyticsClient(
      baseUrl: Uri.parse('http://127.0.0.1:${server.port}'),
      flushTicker: (_) => ticks.stream,
    );
    addTearDown(client.dispose);

    ticks.add(null);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(posted, isEmpty);
  });
}

/// Waits until the local test server recorded a POST, bounded by a deadline —
/// the tick's flush is fire-and-forget, so the POST lands asynchronously.
Future<void> _pollUntilPosted(List<Object> posted) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (posted.isEmpty && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
}
