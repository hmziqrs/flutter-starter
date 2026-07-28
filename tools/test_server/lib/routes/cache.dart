import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

const Map<String, String> _jsonHeaders = <String, String>{
  'content-type': 'application/json; charset=utf-8',
};

/// Default TTL advertised on cache entries that do not specify one (seconds).
const int _defaultTtlSeconds = 300;

/// In-memory cacheable data-source table (C9 — offline-cache test-server
/// contract). The cache route is GET-only: tests prime this map directly via
/// [primeCacheEntry] / [resetCache] to exercise the offline-aware read
/// primitive (`cachedFutureProvider`) against realistic network paths
/// (`If-None-Match`/`304`, `?minEpoch=` conditional fetch).
///
/// Single-process test server only — no persistence across restarts, mirroring
/// the other in-memory route groups (auth/otp/feedback/notifications).
final Map<String, _CacheRecord> _entries = <String, _CacheRecord>{
  // A canonical fixture so a freshly started server serves at least one known
  // key without priming (keeps `GET /v1/cache/welcome` deterministic for the
  // first integration smoke and for documentation).
  'welcome': _CacheRecord(
    data: <String, Object?>{'message': 'Welcome to the starter.'},
    etag: '"welcome-1"',
    ttlSeconds: _defaultTtlSeconds,
    epoch: 1,
  ),
};

final class _CacheRecord {
  const _CacheRecord({
    required this.data,
    required this.etag,
    required this.ttlSeconds,
    required this.epoch,
  });

  final Object? data;
  final String etag;
  final int ttlSeconds;
  final int epoch;

  Map<String, Object?> toPayload() => <String, Object?>{
    'data': data,
    'etag': etag,
    'ttlSeconds': ttlSeconds,
    'epoch': epoch,
  };
}

/// Primes the cache with [entry] under [key]. Test-only seam: the route group
/// exposes no write endpoint (C9 lists only `GET /v1/cache/{key}`), so the
/// offline-aware read primitive is exercised by priming the table directly and
/// then reading through the network path.
void primeCacheEntry(
  String key, {
  required Object? data,
  String? etag,
  int? ttlSeconds,
  int? epoch,
}) {
  _entries[key] = _CacheRecord(
    data: data,
    etag: etag ?? '"$key-1"',
    ttlSeconds: ttlSeconds ?? _defaultTtlSeconds,
    epoch: epoch ?? DateTime.now().toUtc().millisecondsSinceEpoch,
  );
}

/// Clears every primed entry and restores the canonical `welcome` fixture.
/// Call from `setUp` so each test starts from a deterministic table.
void resetCache() {
  _entries
    ..clear()
    ..['welcome'] = _CacheRecord(
      data: <String, Object?>{'message': 'Welcome to the starter.'},
      etag: '"welcome-1"',
      ttlSeconds: _defaultTtlSeconds,
      epoch: 1,
    );
}

/// Mounts the offline-cache contract (C9) onto [router]:
/// - `GET /v1/cache/{key}` -> `200 {data, etag, ttlSeconds, epoch}` for a known
///   key, `304` when `If-None-Match` matches the entry's etag (or `*`), `304`
///   when `?minEpoch=<ts>` is not strictly older than the entry, `404` for an
///   unknown key.
///
/// Mirrors the remote-config conditional-request semantics so the client
/// `cachedFutureProvider` exercises a realistic etag/304 short-circuit and a
/// `minEpoch` freshness gate against real HTTP paths. Never fakes a populated
/// cache for an unknown key — an absent entry is an honest `404`.
void registerRoutes(Router router) {
  router.get('/v1/cache/<key|[A-Za-z0-9_.\\-]+>', _handle);
}

Response _handle(Request request, String key) {
  final record = _entries[key];
  if (record == null) {
    return Response(
      404,
      body: jsonEncode(<String, String>{'error': 'unknown cache key'}),
      headers: _jsonHeaders,
    );
  }

  // Conditional request via If-None-Match (RFC 7232). `*` always matches.
  final ifNoneMatch = request.headers['if-none-match'];
  if (ifNoneMatch == record.etag || ifNoneMatch == '*') {
    return Response.notModified(headers: <String, String>{'etag': record.etag});
  }

  // Conditional request via ?minEpoch=<ts> (mobile-friendly freshness gate):
  // the client asks "is there anything newer than my last seen epoch?". A
  // record whose epoch is NOT strictly greater is "not newer" -> 304.
  final minEpochRaw = request.requestedUri.queryParameters['minEpoch'];
  if (minEpochRaw != null) {
    final minEpoch = int.tryParse(minEpochRaw);
    if (minEpoch != null && record.epoch <= minEpoch) {
      return Response.notModified(headers: <String, String>{'etag': record.etag});
    }
  }

  return Response.ok(
    jsonEncode(record.toPayload()),
    headers: <String, String>{..._jsonHeaders, 'etag': record.etag},
  );
}
