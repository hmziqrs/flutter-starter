import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:starter/infrastructure/cache/cache_entry.dart';
import 'package:starter/infrastructure/cache/cached_future_provider.dart';
import 'package:starter/infrastructure/cache/http_cache_data_source.dart';

const Map<String, Object?> _wireRecord = <String, Object?>{
  'data': <String, Object?>{'message': 'Welcome to the starter.'},
  'etag': '"welcome-1"',
  'ttlSeconds': 300,
  'epoch': 1,
};

const CacheCodec<String> _messageCodec = CacheCodec<String>(
  encode: _identity,
  decode: _decodeMessage,
);

String _identity(String value) => value;

String _decodeMessage(Object? json) =>
    json is Map<String, Object?> ? json['message'] as String? ?? '' : '';

void main() {
  late HttpServer server;
  final ifNoneMatchSent = <String?>[];

  setUp(() async {
    ifNoneMatchSent.clear();
    final bound = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server = bound
      ..listen((request) async {
        if (!request.uri.path.startsWith('/v1/cache/welcome')) {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
          return;
        }
        final ifNoneMatch = request.headers.value(HttpHeaders.ifNoneMatchHeader);
        ifNoneMatchSent.add(ifNoneMatch);
        if (ifNoneMatch == _wireRecord['etag']) {
          request.response.statusCode = HttpStatus.notModified;
          request.response.headers.set(HttpHeaders.etagHeader, _wireRecord['etag']! as String);
          await request.response.close();
          return;
        }
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(_wireRecord));
        await request.response.close();
      });
  });

  tearDown(() => server.close(force: true));

  HttpCacheDataSource source() => HttpCacheDataSource(
    baseUrl: Uri.parse('http://127.0.0.1:${server.port}'),
  );

  test('a 200 parses the full wire shape {data, etag, ttlSeconds, epoch}', () async {
    final result = await source().fetchRecord('welcome');

    expect(
      result,
      isA<CacheFetchModified<HttpCacheRecord>>().having((r) => r.value.epoch, 'epoch', 1),
    );
    final record = (result as CacheFetchModified<HttpCacheRecord>).value;
    expect(record.data, _wireRecord['data']);
    expect(record.etag, '"welcome-1"');
    expect(record.ttlSeconds, 300);
  });

  test('an etag is sent as If-None-Match and a 304 maps to not-modified', () async {
    final result = await source().fetchRecord('welcome', etag: '"welcome-1"');

    expect(result, isA<CacheFetchNotModified<HttpCacheRecord>>());
    expect(ifNoneMatchSent, <String?>['"welcome-1"']);
  });

  test('an unknown key surfaces a typed CacheDataSourceException', () async {
    await expectLater(
      source().fetchRecord('missing'),
      throwsA(
        isA<CacheDataSourceException>().having((e) => e.statusCode, 'statusCode', 404),
      ),
    );
  });

  test('spec() feeds buildCachedFutureProvider: fetch decodes, conditional revalidates', () async {
    final spec = source().spec(key: 'welcome', codec: _messageCodec, ttlSeconds: 60);

    expect(spec.key, 'welcome');
    expect(await spec.fetch(), 'Welcome to the starter.');
    expect(await spec.conditionalFetch!(null), isA<CacheFetchModified<String>>());
    expect(
      await spec.conditionalFetch!('"welcome-1"'),
      isA<CacheFetchNotModified<String>>(),
      reason: 'the stored etag short-circuits as a 304',
    );
  });
}
