import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:test_server/routes/cache.dart' as cache;
import 'package:test_server/server.dart';

void main() {
  late Handler handler;

  setUp(() {
    cache.resetCache();
    handler = buildHandler(enableLogging: false);
  });

  group('GET /v1/cache/{key}', () {
    test('returns the canonical welcome fixture with etag + ttl', () async {
      final response = await handler(
        Request('GET', Uri.parse('http://localhost/v1/cache/welcome')),
      );
      expect(response.statusCode, 200);
      expect(response.headers['content-type'], contains('application/json'));
      expect(response.headers['etag'], '"welcome-1"');

      final body = jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect(body['etag'], '"welcome-1"');
      expect(body['ttlSeconds'], greaterThan(0));
      expect(body['epoch'], isNotNull);
      expect((body['data'] as Map<String, dynamic>)['message'], 'Welcome to the starter.');
    });

    test('responds 404 for an unknown key (never fakes a populated cache)', () async {
      final response = await handler(
        Request('GET', Uri.parse('http://localhost/v1/cache/does-not-exist')),
      );
      expect(response.statusCode, 404);
    });

    test('returns 304 on a matching If-None-Match', () async {
      final response = await handler(
        Request(
          'GET',
          Uri.parse('http://localhost/v1/cache/welcome'),
          headers: <String, String>{'if-none-match': '"welcome-1"'},
        ),
      );
      expect(response.statusCode, 304);
      expect(response.headers['etag'], '"welcome-1"');
    });

    test('returns 304 on If-None-Match: *', () async {
      final response = await handler(
        Request(
          'GET',
          Uri.parse('http://localhost/v1/cache/welcome'),
          headers: <String, String>{'if-none-match': '*'},
        ),
      );
      expect(response.statusCode, 304);
    });

    test('returns 200 when If-None-Match does not match', () async {
      final response = await handler(
        Request(
          'GET',
          Uri.parse('http://localhost/v1/cache/welcome'),
          headers: <String, String>{'if-none-match': '"stale"'},
        ),
      );
      expect(response.statusCode, 200);
    });

    test('?minEpoch= at or above the entry epoch -> 304 (nothing newer)', () async {
      // welcome has epoch 1; asking for anything newer than 1 yields 304.
      final response = await handler(
        Request('GET', Uri.parse('http://localhost/v1/cache/welcome?minEpoch=1')),
      );
      expect(response.statusCode, 304);
    });

    test('?minEpoch= below the entry epoch -> 200 (newer content available)', () async {
      final response = await handler(
        Request('GET', Uri.parse('http://localhost/v1/cache/welcome?minEpoch=0')),
      );
      expect(response.statusCode, 200);
    });

    test('serves primed entries and honors their etag for a 304 short-circuit', () async {
      cache.primeCacheEntry(
        'feature-flag',
        data: <String, Object?>{'enabled': true},
        etag: '"flags-v2"',
        ttlSeconds: 120,
        epoch: 42,
      );

      final first = await handler(
        Request('GET', Uri.parse('http://localhost/v1/cache/feature-flag')),
      );
      expect(first.statusCode, 200);
      expect(first.headers['etag'], '"flags-v2"');
      final body = jsonDecode(await first.readAsString()) as Map<String, dynamic>;
      expect((body['data'] as Map<String, dynamic>)['enabled'], true);
      expect(body['ttlSeconds'], 120);

      // A conditional re-fetch short-circuits via the entry etag.
      final second = await handler(
        Request(
          'GET',
          Uri.parse('http://localhost/v1/cache/feature-flag'),
          headers: <String, String>{'if-none-match': '"flags-v2"'},
        ),
      );
      expect(second.statusCode, 304);

      // minEpoch=42 (== epoch) -> nothing newer -> 304; minEpoch=41 -> 200.
      expect(
        (await handler(
          Request('GET', Uri.parse('http://localhost/v1/cache/feature-flag?minEpoch=42')),
        )).statusCode,
        304,
      );
      expect(
        (await handler(
          Request('GET', Uri.parse('http://localhost/v1/cache/feature-flag?minEpoch=41')),
        )).statusCode,
        200,
      );
    });
  });
}
