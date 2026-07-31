import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/connectivity/connectivity_controller.dart';
import 'package:starter/features/connectivity/connectivity_state.dart';
import 'package:starter/infrastructure/cache/cache_entry.dart';
import 'package:starter/infrastructure/cache/cache_store.dart';
import 'package:starter/infrastructure/cache/cached_future_provider.dart';
import 'package:starter/infrastructure/cache/in_memory_cache_store.dart';

import '../connectivity/fake_connectivity_service.dart';

const String _key = 'test.counter';
const CacheCodec<int> _intCodec = CacheCodec<int>(encode: _encodeInt, decode: _decodeInt);

int _encodeInt(int v) => v;

int _decodeInt(Object? json) => json is int ? json : 0;

int fetchCallCount = 0;
Exception? fetchError;
int fetchValue = 2;

Future<int> fetch() async {
  fetchCallCount += 1;
  final error = fetchError;
  if (error != null) {
    throw error;
  }
  return fetchValue;
}

final FutureProvider<CachedValue<int>> counterProvider = buildCachedFutureProvider<int>(
  const CachedFutureSpec<int>(key: _key, fetch: fetch, codec: _intCodec, ttlSeconds: 1000),
);

Future<void> settle() async {
  for (var i = 0; i < 8; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

ProviderContainer _container({
  required InMemoryCacheStore store,
  required FakeConnectivityService connectivity,
}) {
  // Forcing a listen delivers the connectivity seed before the cached provider builds.
  return ProviderContainer(
    overrides: [
      cacheStoreProvider.overrideWithValue(store),
      connectivityServiceProvider.overrideWithValue(connectivity),
    ],
  )..listen(connectivityStatusProvider, (previous, next) {});
}

CacheEntry<int> _fresh(int value) => CacheEntry<int>(
  value: value,
  fetchedAt: DateTime.now().millisecondsSinceEpoch,
  ttlSeconds: 1000,
);

CacheEntry<int> _stale(int value) => CacheEntry<int>(
  value: value,
  fetchedAt: DateTime.now().millisecondsSinceEpoch - 10000,
  ttlSeconds: 1,
);

void main() {
  setUp(() {
    fetchCallCount = 0;
    fetchError = null;
    fetchValue = 2;
  });

  test('a fresh cache hit is served without calling fetch', () async {
    final store = InMemoryCacheStore();
    await store.write(_key, _fresh(1), codec: _intCodec);
    final container = _container(
      store: store,
      connectivity: FakeConnectivityService(),
    );
    addTearDown(container.dispose);
    await settle();

    final result = await container.read(counterProvider.future);

    expect(result.value, 1);
    expect(result.status, CacheStatus.fresh);
    expect(result.updated, isFalse);
    expect(fetchCallCount, 0);
  });

  test('a stale entry is refreshed when online, then cached', () async {
    final store = InMemoryCacheStore();
    await store.write(_key, _stale(1), codec: _intCodec);
    fetchValue = 2;
    final container = _container(
      store: store,
      connectivity: FakeConnectivityService(),
    );
    addTearDown(container.dispose);
    await settle();

    final result = await container.read(counterProvider.future);

    expect(result.value, 2);
    expect(result.status, CacheStatus.fresh);
    expect(result.updated, isTrue);
    expect(fetchCallCount, 1);

    final cached = await store.read<int>(_key, codec: _intCodec);
    expect(cached, isNotNull);
    expect(cached!.value, 2);
  });

  test('a stale entry is served honestly when offline (no fetch)', () async {
    final store = InMemoryCacheStore();
    await store.write(_key, _stale(1), codec: _intCodec);
    final container = _container(
      store: store,
      connectivity: FakeConnectivityService(initial: ConnectivityState.offline),
    );
    addTearDown(container.dispose);
    await settle();

    final result = await container.read(counterProvider.future);

    expect(result.value, 1);
    expect(result.status, CacheStatus.stale);
    expect(result.isStale, isTrue);
    expect(fetchCallCount, 0);
  });

  test('a stale entry is served when the link is limited (no fetch)', () async {
    final store = InMemoryCacheStore();
    await store.write(_key, _stale(1), codec: _intCodec);
    final container = _container(
      store: store,
      connectivity: FakeConnectivityService(initial: ConnectivityState.limited),
    );
    addTearDown(container.dispose);
    await settle();

    final result = await container.read(counterProvider.future);

    expect(result.value, 1);
    expect(result.isStale, isTrue);
    expect(fetchCallCount, 0);
  });

  test('offline and absent surfaces CacheUnavailable', () async {
    final store = InMemoryCacheStore();
    final container = _container(
      store: store,
      connectivity: FakeConnectivityService(initial: ConnectivityState.offline),
    );
    addTearDown(container.dispose);
    // Keep a subscription so the error transition survives; reading `.future` would race teardown.
    container.read(counterProvider);
    await settle();

    final state = container.read(counterProvider);

    expect(state.hasError, isTrue);
    expect(state.error, isA<CacheUnavailable>());
    expect(fetchCallCount, 0);
  });

  test('absent and online fetches, serves fresh, and caches', () async {
    final store = InMemoryCacheStore();
    fetchValue = 5;
    final container = _container(
      store: store,
      connectivity: FakeConnectivityService(),
    );
    addTearDown(container.dispose);
    await settle();

    final result = await container.read(counterProvider.future);

    expect(result.value, 5);
    expect(result.status, CacheStatus.fresh);
    expect(result.updated, isTrue);
    expect(fetchCallCount, 1);

    final cached = await store.read<int>(_key, codec: _intCodec);
    expect(cached, isNotNull);
    expect(cached!.value, 5);
  });

  test('a fetch failure online degrades to the stale entry', () async {
    final store = InMemoryCacheStore();
    await store.write(_key, _stale(1), codec: _intCodec);
    fetchError = Exception('network down');
    final container = _container(
      store: store,
      connectivity: FakeConnectivityService(),
    );
    addTearDown(container.dispose);
    await settle();

    final result = await container.read(counterProvider.future);

    expect(result.value, 1);
    expect(result.status, CacheStatus.stale);
    expect(fetchCallCount, 1);
  });

  test('a storage read failure is treated as absent (online -> refresh)', () async {
    final store = InMemoryCacheStore();
    await store.write(_key, _fresh(1), codec: _intCodec);
    store.failReads = true;
    fetchValue = 7;
    final container = _container(
      store: store,
      connectivity: FakeConnectivityService(),
    );
    addTearDown(container.dispose);
    await settle();

    final result = await container.read(counterProvider.future);

    expect(result.value, 7);
    expect(result.status, CacheStatus.fresh);
    expect(result.updated, isTrue);
    expect(fetchCallCount, 1);
  });

  test('CacheUnavailable carries the key', () async {
    const exc = CacheUnavailable(key: 'cache.feature.x');

    expect(exc.key, 'cache.feature.x');
    expect(exc.toString(), contains('cache.feature.x'));
  });

  test('CachedValue stale flag reports honestly', () {
    final entry = _fresh(3);

    expect(CachedValue<int>.fresh(entry).isStale, isFalse);
    expect(CachedValue<int>.cached(entry).isStale, isFalse);
    expect(CachedValue<int>.stale(entry).isStale, isTrue);
  });
}
