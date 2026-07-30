import 'package:flutter/foundation.dart';

/// Freshness of a [CacheEntry] at a given instant. Consumers exhaustively
/// switch on this rather than an `if` chain.
enum CacheStatus {
  /// `fetchedAt + ttlSeconds` has not elapsed; the value is served as-is.
  fresh,

  /// TTL elapsed but the entry is still present; served marked stale (e.g.
  /// when offline) rather than as fresh-looking data.
  stale,

  /// No entry exists for the key.
  absent,
}

/// Typed JSON (de)serialization boundary for a cached value of type [T].
///
/// [encode] must return a JSON-serializable value (`null`, `bool`, `num`,
/// `String`, `List`, or `Map<String, Object?>`); [decode] reconstructs [T]
/// from whatever [encode] produced. Const and stateless.
final class CacheCodec<T> {
  const CacheCodec({required this.encode, required this.decode});

  /// Turns a typed [T] value into its JSON-serializable form.
  final Object? Function(T value) encode;

  /// Reconstructs a typed [T] value from its JSON form.
  final T Function(Object? json) decode;

  /// Codec for a plain [String] value (identity in both directions).
  static const CacheCodec<String> string = CacheCodec<String>(
    encode: _identityString,
    decode: _decodeString,
  );

  /// Codec for an arbitrary already-JSON-compatible value, stored verbatim
  /// and read back as [Object?]. Prefer a typed domain codec otherwise.
  static const CacheCodec<Object?> json = CacheCodec<Object?>(
    encode: _identityObject,
    decode: _identityObject,
  );

  static Object? _identityString(String value) => value;

  static String _decodeString(Object? json) => json is String ? json : '';

  static Object? _identityObject(Object? value) => value;
}

/// An immutable, value-equal cached entry for a typed value [T]. Pairs the
/// fetched [value] with its provenance ([fetchedAt], [ttlSeconds], optional
/// [etag]) so a reader can decide freshness without re-fetching.
@immutable
final class CacheEntry<T> {
  /// Creates an immutable cached entry.
  const CacheEntry({
    required this.value,
    required this.fetchedAt,
    required this.ttlSeconds,
    this.etag,
  }) : assert(ttlSeconds >= 0, 'ttlSeconds must not be negative.');

  /// The typed cached payload.
  final T value;

  /// Epoch milliseconds at which [value] was fetched.
  final int fetchedAt;

  /// Seconds the entry is [CacheStatus.fresh] starting at [fetchedAt]. `0`
  /// makes the entry stale immediately.
  final int ttlSeconds;

  /// Optional opaque validator (e.g. HTTP `ETag`) carried through verbatim,
  /// never interpreted, so a refresh can send `If-None-Match`.
  final String? etag;

  /// Freshness at [now]. Fresh while `now < fetchedAt + ttlSeconds`; stale
  /// thereafter. Pure and clock-free: pass a faked `now` in tests.
  CacheStatus statusAt(DateTime now) {
    final expiresAt = fetchedAt + ttlSeconds * Duration.millisecondsPerSecond;
    return now.millisecondsSinceEpoch < expiresAt ? CacheStatus.fresh : CacheStatus.stale;
  }

  /// Whole seconds remaining before the entry turns stale at [now], or `0`
  /// once it is stale. Never negative (clamped) so countdown copy is safe.
  int freshSecondsRemainingAt(DateTime now) {
    final remaining =
        (fetchedAt + ttlSeconds * Duration.millisecondsPerSecond) - now.millisecondsSinceEpoch;
    return remaining <= 0 ? 0 : remaining ~/ Duration.millisecondsPerSecond;
  }

  /// Elapsed since [fetchedAt] at [now]. May be negative under clock skew;
  /// callers that display it should clamp at zero.
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

/// The on-disk / in-memory wire shape of a [CacheEntry]. Both `CacheStore`
/// adapters serialize to and from this canonical map so they behave
/// identically; the typed value crosses the boundary via a [CacheCodec].
typedef CacheEntryJson = Map<String, Object?>;

const String _kValue = 'value';
const String _kFetchedAt = 'fetchedAt';
const String _kTtlSeconds = 'ttlSeconds';
const String _kEtag = 'etag';

/// Serializes [entry] to its canonical [CacheEntryJson] form using [codec] to
/// encode the value. Pure; the store writes this map verbatim.
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

/// Reconstructs a typed [CacheEntry<T>] from its canonical [CacheEntryJson]
/// form using [codec] to decode the value. Throws [FormatException] on a
/// corrupted/short shape; the store wraps that in `CacheStoreException`.
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

/// Reads the `fetchedAt` epoch-millis field from a raw entry payload without
/// decoding the value. Used by `CacheStore.age` so it stays codec-free.
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
