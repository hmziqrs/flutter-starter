import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:starter/features/experiments/experiment_key.dart';
import 'package:starter/features/experiments/experiment_source.dart';
import 'package:starter/features/experiments/experiment_variant.dart';
import 'package:starter/features/settings/settings_store.dart';

/// Deterministic [ExperimentSource] — the no-backend production default.
///
/// Hashes a stable device id (read once from [store], persisted under
/// [stableIdKey]) per [ExperimentKey] into a variant bucket using a fixed
/// allocation table. This is a real local assignment (stable, reproducible
/// across launches, no network), not a Noop.
///
/// Constructed in `AppDependencies.production`. The optional
/// `RemoteConfigExperimentSource` degrades to this table when offline rather
/// than throwing.
///
/// The hash is FNV-1a (32-bit) over `"$salt:$stableId:$wireKey"` — stable
/// across Dart isolates and the web target (unlike `String.hashCode`); the
/// salt keeps the bucket non-reversible to a device fingerprint. Do not
/// change the hash function or salt scheme without accepting a re-bucketing
/// of all existing assignments.
final class DeterministicExperimentSource implements ExperimentSource {
  /// Constructs a deterministic source that persists the stable device id
  /// under [stableIdKey] in [store], hashing with [salt]. [randomSeed] is
  /// injectable for tests; defaults to [Random.secure] in production.
  DeterministicExperimentSource({
    required this.store,
    this.salt = defaultSalt,
    this.stableIdKey = defaultStableIdKey,
    Random? randomSeed,
  }) : random = randomSeed ?? Random.secure();

  /// SettingsStore key under which the stable device id is persisted.
  static const defaultStableIdKey = 'experiments.deviceStableId';

  /// Default hash salt. Versioned so a future re-bucketing rollout can change
  /// the mapping deliberately by bumping the suffix.
  static const defaultSalt = 'starter.abex.v1';

  /// The backing key/value store the stable device id is persisted in.
  final SettingsStore store;

  /// Hash salt mixed into every bucket input.
  final String salt;

  /// SettingsStore key for the stable device id.
  final String stableIdKey;

  /// The random generator used to mint a fresh stable id.
  final Random random;

  /// Cached stable id for the lifetime of this source instance, so a single
  /// session never re-hashes against a fresh id (the sticky-assignment
  /// contract).
  String? _cachedStableId;

  @override
  Future<ExperimentAssignment> assignmentFor(ExperimentKey key) async {
    final stableId = await _stableId();
    return ExperimentAssignment(
      key: key,
      variant: _bucket(key, stableId),
      sticky: true,
      source: ExperimentAssignmentSource.local,
    );
  }

  @override
  Stream<List<ExperimentAssignment>> changes() => const Stream<List<ExperimentAssignment>>.empty();

  /// Returns the stable device id, reading it from [store] (caching +
  /// persisting a freshly generated id on first contact). A read or write
  /// failure still returns a generated id for the session; it just won't
  /// persist.
  Future<String> _stableId() async {
    final cached = _cachedStableId;
    if (cached != null) {
      return cached;
    }
    String? existing;
    try {
      existing = await store.readString(stableIdKey);
    } on Object {
      existing = null;
    }
    if (existing != null && existing.isNotEmpty) {
      _cachedStableId = existing;
      return existing;
    }
    final generated = _generateId();
    try {
      await store.writeString(stableIdKey, generated);
    } on Object {
      // Persist failed; the in-memory id is used for this session only.
    }
    _cachedStableId = generated;
    return generated;
  }

  /// Generates a fresh 128-bit stable id as a 32-char hex string.
  String _generateId() {
    final bytes = Uint8List(16);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return _toHex(bytes);
  }

  /// Buckets [stableId] into a variant arm for [key] using its allocation
  /// table. A zero-weight table degrades to the control arm. The bucket
  /// input is scoped per [ExperimentKey.wireKey], so adding a new experiment
  /// never re-buckets an existing one.
  @visibleForTesting
  ExperimentVariant bucket(ExperimentKey key, String stableId) => _bucket(key, stableId);

  ExperimentVariant _bucket(ExperimentKey key, String stableId) {
    final total = key.totalWeight;
    if (total <= 0) {
      return const ExperimentVariantControl();
    }
    final bucket = _fnv1a32('$salt:$stableId:${key.wireKey}') % total;
    var cumulative = 0;
    for (final allocation in key.allocations) {
      cumulative += allocation.weight;
      if (bucket < cumulative) {
        return ExperimentVariant.forKind(allocation.variant);
      }
    }
    // Unreachable when weights are non-negative and sum > 0 (modulo keeps the
    // bucket below `total`); kept as a type-safe fallback.
    return const ExperimentVariantControl();
  }

  /// Stable FNV-1a (32-bit) hash of [input], returned as a non-negative
  /// integer.
  static int _fnv1a32(String input) {
    const offsetBasis = 0x811c9dc5;
    const prime = 0x01000193;
    const mask = 0xFFFFFFFF;
    var hash = offsetBasis;
    for (final byte in utf8.encode(input)) {
      hash ^= byte;
      hash = (hash * prime) & mask;
    }
    // Strip the sign bit so modulo arithmetic is clean and non-negative.
    return hash & 0x7FFFFFFF;
  }
}

/// Lowercase hex encoder for the 16-byte stable id.
String _toHex(Uint8List bytes) {
  const alphabet = '0123456789abcdef';
  final out = StringBuffer();
  for (final byte in bytes) {
    out
      ..write(alphabet[(byte >> 4) & 0x0F])
      ..write(alphabet[byte & 0x0F]);
  }
  return out.toString();
}
