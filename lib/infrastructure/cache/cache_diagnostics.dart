import 'package:starter/infrastructure/cache/cache_store.dart';

/// Cache keys the starter may have persisted; the dev-only diagnostics dump
/// renders one row per key (absent rows included). Features adopting
/// `cachedFutureProvider` register their key here; `welcome` is the reference
/// key of the test server's `GET /v1/cache/{key}` route group and
/// `search-corpus` mirrors the search feature's `searchCorpusCacheKey`
/// (infrastructure cannot import the feature constant itself).
const Set<String> knownCacheKeys = <String>{'welcome', 'search-corpus'};

final class CacheDiagnosticRow {
  const CacheDiagnosticRow({required this.key, required this.age, required this.present});

  final String key;

  final Duration? age;

  final bool present;

  @override
  String toString() =>
      'CacheDiagnosticRow(key: $key, present: $present, age: ${age?.inSeconds ?? '-'}s)';
}

Future<List<CacheDiagnosticRow>> cacheDiagnosticsSnapshot(
  CacheStore store, {
  Iterable<String> keys = const <String>[],
}) async {
  final rows = <CacheDiagnosticRow>[];
  for (final key in keys) {
    Duration? age;
    try {
      age = await store.age(key);
    } on Object {
      age = null;
    }
    rows.add(CacheDiagnosticRow(key: key, age: age, present: age != null));
  }
  return rows;
}
