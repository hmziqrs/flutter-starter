import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:starter/infrastructure/cache/cache_entry.dart';
import 'package:starter/infrastructure/cache/cached_future_provider.dart';
import 'package:starter/infrastructure/http/app_dio.dart';

/// A cacheable record exactly as the generic `GET /v1/cache/{key}` route group
/// serves it: `{data, etag, ttlSeconds, epoch}`.
@immutable
final class HttpCacheRecord {
  const HttpCacheRecord({
    required this.data,
    required this.etag,
    required this.ttlSeconds,
    required this.epoch,
  });

  final Object? data;

  final String? etag;

  final int ttlSeconds;

  /// Server-side version counter for the record (monotonic per key).
  final int epoch;

  static HttpCacheRecord? tryParse(Object? body) {
    if (body is! Map<String, Object?>) {
      return null;
    }
    final ttlSeconds = body['ttlSeconds'];
    final epoch = body['epoch'];
    final etag = body['etag'];
    if (ttlSeconds is! int || epoch is! int) {
      return null;
    }
    return HttpCacheRecord(
      data: body['data'],
      etag: etag is String ? etag : null,
      ttlSeconds: ttlSeconds,
      epoch: epoch,
    );
  }
}

/// The cache route answered with a non-recoverable status or a malformed body.
final class CacheDataSourceException implements Exception {
  const CacheDataSourceException(this.message, {this.statusCode});

  final String message;

  final int? statusCode;

  @override
  String toString() =>
      'CacheDataSourceException: $message${statusCode == null ? '' : ' (HTTP $statusCode)'}';
}

/// HTTP data source for the offline-aware cache primitive: performs
/// (conditional) GETs against `/v1/cache/{key}` and feeds
/// [buildCachedFutureProvider] via [spec].
final class HttpCacheDataSource {
  HttpCacheDataSource({
    required Uri baseUrl,
    this.timeout = const Duration(seconds: 5),
    Dio? dio,
  }) : _dio = dio ?? buildAppDio(baseUrl) {
    if (dio == null) {
      _dio.options
        ..connectTimeout = timeout
        ..sendTimeout = timeout
        ..receiveTimeout = timeout;
    }
  }

  final Duration timeout;

  final Dio _dio;

  /// GETs `/v1/cache/{key}`. When [etag] is non-null it is sent as
  /// `If-None-Match`, so an unchanged record short-circuits as a 304
  /// ([CacheFetchNotModified]) instead of a full body.
  ///
  /// Throws [CacheDataSourceException] on a non-200/304 status or a malformed
  /// body; transport failures surface as `DioException`. Callers
  /// (`cachedFutureProvider`) degrade both to the stale entry.
  Future<CacheFetch<HttpCacheRecord>> fetchRecord(String key, {String? etag}) async {
    final response = await _dio.get<String>(
      '/v1/cache/$key',
      options: Options(
        responseType: ResponseType.plain,
        headers: etag == null ? null : <String, String>{'if-none-match': etag},
      ),
    );
    final status = response.statusCode ?? 0;
    if (status == 304) {
      return const CacheFetchNotModified<HttpCacheRecord>();
    }
    if (status != 200) {
      throw CacheDataSourceException('cache fetch failed for "$key"', statusCode: status);
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(response.data ?? '');
    } on FormatException {
      throw const CacheDataSourceException('cache payload is not valid JSON');
    }
    final record = HttpCacheRecord.tryParse(decoded);
    if (record == null) {
      throw const CacheDataSourceException('cache payload is missing required fields');
    }
    return CacheFetchModified<HttpCacheRecord>(
      value: record,
      etag: record.etag,
      ttlSeconds: record.ttlSeconds,
    );
  }

  /// [fetchRecord] decoded through [codec] into the feature's value type.
  Future<CacheFetch<T>> fetch<T>(String key, {required CacheCodec<T> codec, String? etag}) async {
    final result = await fetchRecord(key, etag: etag);
    switch (result) {
      case CacheFetchNotModified<HttpCacheRecord>():
        return CacheFetchNotModified<T>();
      case CacheFetchModified<HttpCacheRecord>(:final value, :final etag, :final ttlSeconds):
        return CacheFetchModified<T>(
          value: codec.decode(value.data),
          etag: etag,
          ttlSeconds: ttlSeconds,
        );
    }
  }

  /// Builds a [CachedFutureSpec] wired to this source, ready for
  /// [buildCachedFutureProvider]: the first (uncached) read performs a plain
  /// GET, later refreshes send the stored etag as `If-None-Match`.
  CachedFutureSpec<T> spec<T>({
    required String key,
    required CacheCodec<T> codec,
    required int ttlSeconds,
  }) {
    return CachedFutureSpec<T>(
      key: key,
      fetch: () async {
        final result = await fetch<T>(key, codec: codec);
        return switch (result) {
          CacheFetchModified<T>(:final value) => value,
          CacheFetchNotModified<T>() => throw const CacheDataSourceException(
            'not-modified (304) on an unconditional fetch',
          ),
        };
      },
      conditionalFetch: (etag) => fetch<T>(key, codec: codec, etag: etag),
      codec: codec,
      ttlSeconds: ttlSeconds,
    );
  }
}
