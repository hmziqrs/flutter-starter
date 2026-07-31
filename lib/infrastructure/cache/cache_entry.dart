import 'package:flutter/foundation.dart';

enum CacheStatus {
  fresh,

  stale,

  absent,
}

final class CacheCodec<T> {
  const CacheCodec({required this.encode, required this.decode});

  final Object? Function(T value) encode;

  final T Function(Object? json) decode;

  static const CacheCodec<String> string = CacheCodec<String>(
    encode: _identityString,
    decode: _decodeString,
  );

  static const CacheCodec<Object?> json = CacheCodec<Object?>(
    encode: _identityObject,
    decode: _identityObject,
  );

  static Object? _identityString(String value) => value;

  static String _decodeString(Object? json) => json is String ? json : '';

  static Object? _identityObject(Object? value) => value;
}

@immutable
final class CacheEntry<T> {
  const CacheEntry({
    required this.value,
    required this.fetchedAt,
    required this.ttlSeconds,
    this.etag,
  }) : assert(ttlSeconds >= 0, 'ttlSeconds must not be negative.');

  final T value;

  final int fetchedAt;

  final int ttlSeconds;

  final String? etag;

  CacheStatus statusAt(DateTime now) {
    final expiresAt = fetchedAt + ttlSeconds * Duration.millisecondsPerSecond;
    return now.millisecondsSinceEpoch < expiresAt ? CacheStatus.fresh : CacheStatus.stale;
  }

  int freshSecondsRemainingAt(DateTime now) {
    final remaining =
        (fetchedAt + ttlSeconds * Duration.millisecondsPerSecond) - now.millisecondsSinceEpoch;
    return remaining <= 0 ? 0 : remaining ~/ Duration.millisecondsPerSecond;
  }

  Duration ageAt(DateTime now) {
    return Duration(milliseconds: now.millisecondsSinceEpoch - fetchedAt);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CacheEntry<T> &&
            value == other.value &&
            fetchedAt == other.fetchedAt &&
            ttlSeconds == other.ttlSeconds &&
            etag == other.etag;
  }

  @override
  int get hashCode => Object.hash(value, fetchedAt, ttlSeconds, etag);

  @override
  String toString() {
    final etagPart = etag == null ? '' : ', etag: $etag';
    return 'CacheEntry<$T>(fetchedAt: $fetchedAt, ttlSeconds: $ttlSeconds$etagPart)';
  }
}

typedef CacheEntryJson = Map<String, Object?>;

const String _kValue = 'value';
const String _kFetchedAt = 'fetchedAt';
const String _kTtlSeconds = 'ttlSeconds';
const String _kEtag = 'etag';

CacheEntryJson cacheEntryToJson<T>(CacheEntry<T> entry, CacheCodec<T> codec) {
  final json = <String, Object?>{
    _kValue: codec.encode(entry.value),
    _kFetchedAt: entry.fetchedAt,
    _kTtlSeconds: entry.ttlSeconds,
  };
  final etag = entry.etag;
  if (etag != null) {
    json[_kEtag] = etag;
  }
  return json;
}

CacheEntry<T> cacheEntryFromJson<T>(Object? raw, CacheCodec<T> codec) {
  if (raw is! Map<String, Object?>) {
    throw const FormatException('Cache entry payload is not a JSON object.');
  }
  final etagRaw = raw[_kEtag];
  return CacheEntry<T>(
    value: codec.decode(raw[_kValue]),
    fetchedAt: _decodeInt(raw[_kFetchedAt]),
    ttlSeconds: _decodeInt(raw[_kTtlSeconds]),
    etag: etagRaw is String ? etagRaw : null,
  );
}

int? cacheEntryFetchedAt(Object? raw) {
  if (raw is! Map<String, Object?>) {
    return null;
  }
  final field = raw[_kFetchedAt];
  return field is int ? field : (field is num ? field.toInt() : null);
}

int _decodeInt(Object? field) {
  if (field is int) {
    return field;
  }
  if (field is num) {
    return field.toInt();
  }
  throw const FormatException('Cache entry numeric field is missing or not a number.');
}
