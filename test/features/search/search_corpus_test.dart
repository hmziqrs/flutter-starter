import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/connectivity/connectivity_controller.dart';
import 'package:starter/features/search/search_corpus.dart';
import 'package:starter/infrastructure/cache/cache_store.dart';
import 'package:starter/infrastructure/cache/http_cache_data_source.dart';
import 'package:starter/infrastructure/cache/in_memory_cache_store.dart';

import '../../infrastructure/connectivity/fake_connectivity_service.dart';

const Map<String, Object?> _wireRecord = <String, Object?>{
  'data': <Object?>[
    <String, Object?>{'id': 'remote-alpha', 'title': 'Remote Alpha'},
    <String, Object?>{'id': 'remote-beta', 'title': 'Remote Beta'},
  ],
  'etag': '"search-corpus-1"',
  'ttlSeconds': 300,
  'epoch': 1,
};

void main() {
  late HttpServer server;
  late bool serveCorpus;

  setUp(() async {
    serveCorpus = true;
    final bound = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server = bound
      ..listen((request) async {
        final ifNoneMatch = request.headers.value(HttpHeaders.ifNoneMatchHeader);
        if (request.uri.path != '/v1/cache/$searchCorpusCacheKey' ||
            !serveCorpus ||
            ifNoneMatch == _wireRecord['etag']) {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
          return;
        }
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(_wireRecord));
        await request.response.close();
      });
  });

  tearDown(() => server.close(force: true));

  // `source` null (the default) leaves searchCorpusSourceProvider unoverridden,
  // so the no-source rung exercises the composition-root default itself.
  ProviderContainer container({CacheStore? cacheStore, HttpCacheDataSource? source}) {
    return ProviderContainer(
      overrides: [
        if (source != null) searchCorpusSourceProvider.overrideWithValue(source),
        cacheStoreProvider.overrideWithValue(cacheStore ?? InMemoryCacheStore()),
        connectivityServiceProvider.overrideWithValue(FakeConnectivityService()),
      ],
    )..listen(connectivityStatusProvider, (_, _) {});
  }

  // Reads across bounded event-loop turns: fixtures serve first, the fetched
  // corpus lands once the cached fetch resolves.
  Future<List<String>> readCorpus(ProviderContainer c) async {
    var ids = const <String>[];
    for (var i = 0; i < 16; i += 1) {
      await Future<void>.delayed(Duration.zero);
      final results = await c.read(searchCorpusProvider.future);
      ids = <String>[for (final result in results) result.id];
    }
    return ids;
  }

  test('an online source serves the fetched corpus and caches its etag', () async {
    final store = InMemoryCacheStore();
    final c = container(
      cacheStore: store,
      source: HttpCacheDataSource(baseUrl: Uri.parse('http://127.0.0.1:${server.port}')),
    );
    addTearDown(c.dispose);

    expect(await readCorpus(c), <String>['remote-alpha', 'remote-beta']);
    final cached = await store.read(searchCorpusCacheKey, codec: searchCorpusCodec);
    expect(cached?.etag, '"search-corpus-1"', reason: 'the fetched corpus is cached');
  });

  test('no source wired keeps search on the bundled fixtures', () async {
    final c = container();
    addTearDown(c.dispose);

    final ids = await readCorpus(c);
    expect(ids, isNotEmpty);
    expect(ids.first, 'search-result-auth', reason: 'the bundled fixture corpus, verbatim');
    expect(ids, everyElement(startsWith('search-result-')));
  });

  test('an unknown cache key degrades honestly to the bundled corpus', () async {
    serveCorpus = false;
    final c = container(
      source: HttpCacheDataSource(baseUrl: Uri.parse('http://127.0.0.1:${server.port}')),
    );
    addTearDown(c.dispose);

    final ids = await readCorpus(c);
    expect(ids, isNotEmpty);
    expect(
      ids,
      everyElement(startsWith('search-result-')),
      reason: 'an unservable remote falls back to the bundled corpus, never an error page',
    );
  });
}
