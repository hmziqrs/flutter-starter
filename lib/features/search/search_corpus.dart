import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/search/search_view_data.dart';
import 'package:starter/infrastructure/cache/cache_entry.dart';
import 'package:starter/infrastructure/cache/cached_future_provider.dart';
import 'package:starter/infrastructure/cache/http_cache_data_source.dart';

/// Cache key of the remote corpus (`GET /v1/cache/search-corpus`) and its
/// freshness window; a 200's server-advertised TTL wins when present.
const String searchCorpusCacheKey = 'search-corpus';
const int searchCorpusTtlSeconds = 300;

/// Wire shape of the corpus: `[{id, title, subtitle}]`. Malformed payloads
/// throw [FormatException] rather than silently synthesizing results.
const CacheCodec<List<SearchResultViewData>> searchCorpusCodec =
    CacheCodec<List<SearchResultViewData>>(
      encode: _encodeCorpus,
      decode: _decodeCorpus,
    );

/// The corpus source seam: the shared HTTP fetcher for `/v1/cache/{key}`.
/// Constructing the concrete adapter belongs to the composition root
/// (contracts §4); the default `null` keeps search on the bundled corpus
/// until a backend is wired there.
final Provider<HttpCacheDataSource?> searchCorpusSourceProvider = Provider<HttpCacheDataSource?>(
  (ref) => null,
);

/// The corpus fetch through the offline-aware cache primitive with the HTTP
/// fetcher's conditional spec (stored etag → `If-None-Match` 304); `null`
/// while no source is wired — nothing to cache then.
final Provider<FutureProvider<CachedValue<List<SearchResultViewData>>>?>
searchCorpusCachedProvider = Provider<FutureProvider<CachedValue<List<SearchResultViewData>>>?>((
  ref,
) {
  final source = ref.watch(searchCorpusSourceProvider);
  if (source == null) {
    return null;
  }
  return buildCachedFutureProvider<List<SearchResultViewData>>(
    source.spec(
      key: searchCorpusCacheKey,
      codec: searchCorpusCodec,
      ttlSeconds: searchCorpusTtlSeconds,
    ),
  );
});

/// The corpus search matches against. With a source wired, the value comes
/// from the cached fetch (fresh → stale-offline → fetched record); while the
/// fetch is in flight or failed (unknown key, transport error, offline with
/// nothing cached), search serves the bundled fixture corpus until a fetch
/// succeeds — never a synthesized list.
final FutureProvider<List<SearchResultViewData>> searchCorpusProvider =
    FutureProvider<List<SearchResultViewData>>((ref) async {
      final cachedProvider = ref.watch(searchCorpusCachedProvider);
      if (cachedProvider == null) {
        return SearchViewData.defaults().results;
      }
      // Watch the AsyncValue (not `.future`): a failed fetch stays retry-
      // pending under Riverpod's default backoff; degrade to fixtures now.
      return ref.watch(cachedProvider).value?.value ?? SearchViewData.defaults().results;
    });

Object? _encodeCorpus(List<SearchResultViewData> results) {
  return <Map<String, Object?>>[
    for (final result in results)
      <String, Object?>{
        'id': result.id,
        'title': result.title,
        'subtitle': result.subtitle,
      },
  ];
}

List<SearchResultViewData> _decodeCorpus(Object? json) {
  if (json is! List<Object?>) {
    throw const FormatException('Search corpus payload is not a JSON list.');
  }
  return <SearchResultViewData>[
    for (final entry in json)
      SearchResultViewData(
        id: _decodeStringField(entry, 'id'),
        title: _decodeStringField(entry, 'title'),
        subtitle: _decodeStringField(entry, 'subtitle', optional: true),
      ),
  ];
}

String _decodeStringField(Object? entry, String name, {bool optional = false}) {
  final value = entry is Map<String, Object?> ? entry[name] : null;
  if (value is String && (value.isNotEmpty || optional)) {
    return value;
  }
  if (optional) return '';
  throw FormatException('Search corpus entry has no valid "$name" field.');
}
