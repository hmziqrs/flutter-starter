import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/connectivity/connectivity_controller.dart';
import 'package:starter/features/connectivity/connectivity_state.dart';
import 'package:starter/infrastructure/cache/cache_entry.dart';
import 'package:starter/infrastructure/cache/cache_store.dart';
import 'package:starter/infrastructure/cache/cached_future_provider.dart';
import 'package:starter/infrastructure/cache/http_cache_data_source.dart';
import 'package:starter/infrastructure/cache/in_memory_cache_store.dart';
import 'package:starter/infrastructure/http/app_dio.dart';

import '../infrastructure/connectivity/fake_connectivity_service.dart';
import '../infrastructure/hono_server_handle.dart';

/// Live cache e2e: `HttpCacheDataSource` + the offline-aware
/// `buildCachedFutureProvider` against the real `GET /v1/cache/:key` route of
/// the live JS Hono server — etag/304 short-circuit, offline stale-serve, and
/// online refresh.
void main() {
  final runtime = JsRuntime.resolve();

  group('cache e2e (HttpCacheDataSource <-> live JS Hono)', () {
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
    late final HttpCacheDataSource source;
    var requestCount = 0;
    String? lastIfNoneMatch;

    setUpAll(() async {
      final handle = await HonoServerHandle.start(runtime: runtime);
      server = handle;
      baseUri = handle.baseUri;
      final dio = buildAppDio(baseUri)
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              requestCount += 1;
              lastIfNoneMatch = options.headers['if-none-match'] as String?;
              handler.next(options);
            },
          ),
        );
      source = HttpCacheDataSource(baseUrl: baseUri, dio: dio);
    });

    tearDownAll(() async {
      final handle = server;
      if (handle != null) await handle.close();
    });

    const cacheKey = 'welcome';
    const mapCodec = CacheCodec<Map<String, Object?>>(
      encode: _identityMap,
      decode: _decodeMap,
    );

    ProviderContainer container({
      required InMemoryCacheStore store,
      required FakeConnectivityService connectivity,
    }) {
      return ProviderContainer(
        overrides: [
          cacheStoreProvider.overrideWithValue(store),
          connectivityServiceProvider.overrideWithValue(connectivity),
        ],
      )..listen(connectivityStatusProvider, (previous, next) {});
    }

    CacheEntry<Map<String, Object?>> staleSavedEntry() => CacheEntry<Map<String, Object?>>(
      value: const <String, Object?>{'message': 'saved offline'},
      fetchedAt: DateTime.now().millisecondsSinceEpoch - 10000,
      ttlSeconds: 1,
      etag: '"welcome-1"',
    );

    Future<void> settle() async {
      for (var i = 0; i < 8; i++) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    test('online refresh (absent store) serves the live 200 and caches etag + TTL', () async {
      final store = InMemoryCacheStore();
      final c = container(store: store, connectivity: FakeConnectivityService());
      addTearDown(c.dispose);
      final provider = buildCachedFutureProvider<Map<String, Object?>>(
        source.spec(key: cacheKey, codec: mapCodec, ttlSeconds: 60),
      );

      await settle();
      final result = await c.read(provider.future);

      expect(result.updated, isTrue);
      expect(result.status, CacheStatus.fresh);
      expect(result.value, <String, Object?>{'message': 'Welcome to the starter.'});

      final cached = await store.read<Map<String, Object?>>(cacheKey, codec: mapCodec);
      expect(cached, isNotNull);
      expect(cached!.etag, '"welcome-1"', reason: 'the etag from the live 200 is stored');
      expect(cached.ttlSeconds, 300, reason: 'the server-advertised TTL is stored');
    });

    test('a stale entry online short-circuits via If-None-Match 304 (fresh-extend)', () async {
      final store = InMemoryCacheStore();
      await store.write(cacheKey, staleSavedEntry(), codec: mapCodec);
      final c = container(store: store, connectivity: FakeConnectivityService());
      addTearDown(c.dispose);
      final provider = buildCachedFutureProvider<Map<String, Object?>>(
        source.spec(key: cacheKey, codec: mapCodec, ttlSeconds: 60),
      );

      await settle();
      final result = await c.read(provider.future);

      expect(lastIfNoneMatch, '"welcome-1"', reason: 'the stored etag hit the live socket');
      expect(result.value, <String, Object?>{
        'message': 'saved offline',
      }, reason: 'a 304 keeps the cached body');
      expect(result.status, CacheStatus.fresh, reason: 'the TTL window restarts');
      expect(result.updated, isFalse, reason: 'no body was re-downloaded');
    });

    test('offline, a stale entry is served honestly without touching the socket', () async {
      final store = InMemoryCacheStore();
      await store.write(cacheKey, staleSavedEntry(), codec: mapCodec);
      final c = container(
        store: store,
        connectivity: FakeConnectivityService(initial: ConnectivityState.offline),
      );
      addTearDown(c.dispose);
      final provider = buildCachedFutureProvider<Map<String, Object?>>(
        source.spec(key: cacheKey, codec: mapCodec, ttlSeconds: 60),
      );
      final requestsBefore = requestCount;

      await settle();
      final result = await c.read(provider.future);

      expect(result.value, <String, Object?>{'message': 'saved offline'});
      expect(result.isStale, isTrue, reason: 'offline staleness is labeled, never hidden');
      expect(requestCount, requestsBefore, reason: 'no request leaves the client offline');
    });
  });
}

Map<String, Object?> _identityMap(Map<String, Object?> value) => value;

Map<String, Object?> _decodeMap(Object? json) =>
    json is Map<String, Object?> ? json : const <String, Object?>{};
