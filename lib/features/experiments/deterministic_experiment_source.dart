import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:starter/features/experiments/experiment_key.dart';
import 'package:starter/features/experiments/experiment_source.dart';
import 'package:starter/features/experiments/experiment_variant.dart';
import 'package:starter/features/settings/settings_store.dart';

/// Deterministic [ExperimentSource] — the no-backend production default.
///
/// Hashes a stable device id (read once from [store] and persisted under
/// [stableIdKey]) per [ExperimentKey] into a variant bucket using a fixed
/// allocation table. This is a **real** local assignment (stable, reproducible
/// across launches and controller rebuilds, no network), not a Noop — so the UI
/// can branch meaningfully on a variant without a backend (C2: the honest
/// no-backend baseline is a real deterministic resolution, never faked remote
/// data).
///
/// Constructed in `AppDependencies.production`. The optional
/// `RemoteConfigExperimentSource` reads the `experiments` slice of the shared
/// remote-config response and **degrades to this table** when offline rather
/// than throwing (C4: one backend, three readers; C2: never fabricate).
///
/// The hash is FNV-1a (32-bit) over `"$salt:$stableId:$wireKey"`. FNV-1a is
/// stable across Dart isolates and platforms (unlike `String.hashCode`, which
/// is not guaranteed stable on the web target); the salt makes the mapping
/// non-obvious so the bucket is not reversible to a device fingerprint. The
/// stable id itself is generated with [Random.secure] and persisted once; the
/// `LogRedactor` scrubs `deviceId` if it ever appears in a log (the salt here is
/// the load-bearing non-reversibility guard at this layer).
final class DeterministicExperimentSource implements ExperimentSource {
  /// Constructs a deterministic source that persists the stable device id under
  /// [stableIdKey] in [store], hashing with [salt]. The [randomSeed] generator
  /// is injectable for tests that need a deterministic id seed; it defaults to
  /// [Random.secure] in production.
  DeterministicExperimentSource({
    required this.store,
    this.salt = defaultSalt,
    this.stableIdKey = defaultStableIdKey,
    Random? randomSeed,
  }) : random = randomSeed ?? Random.secure();

  /// SettingsStore key under which the stable device id is persisted (per-key
  /// discipline — no `clearAll`). Surfaced so the diagnostics surface and tests
  /// can reference the canonical key.
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

  /// The random generator used to mint a fresh stable id (secure in production;
  /// seedable in tests).
  final Random random;

  /// Cached stable id for the lifetime of this source instance. Once read or
  /// generated, every [assignmentFor] call reuses it so a single session never
  /// re-hashes against a fresh id (the sticky-assignment contract).
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

  /// Returns the stable device id, reading it from [store] (and caching +
  /// persisting a freshly generated id on first contact). A read or write
  /// failure degrades honestly: a generated id is still used for the session so
  /// the UI never blocks, but it will not persist (a user who clears app data
  /// may re-bucket, which the spec accepts).
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
      // Persist failed; the in-memory id is still used for this session so the
      // UI renders, but it will not survive a restart. Degrade honestly.
    }
    _cachedStableId = generated;
    return generated;
  }

  /// Generates a fresh 128-bit stable id as a 32-char hex string. Uses the
  /// injected [random] (secure in production; seedable in tests).
  String _generateId() {
    final bytes = Uint8List(16);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return _toHex(bytes);
  }

  /// Buckets [stableId] into a variant arm for [key] using the experiment's
  /// allocation table. A zero-weight table degrades to the control arm
  /// (defensive — the const tables are all non-zero). The bucket input is
  /// scoped per [ExperimentKey.wireKey], so adding a new experiment never
  /// re-buckets an existing one.
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
    // Unreachable when weights are non-negative and sum > 0; the modulo keeps
    // the bucket below `total`, so some arm always matches. Kept as a
    // type-safe control fallback rather than throwing.
    return const ExperimentVariantControl();
  }

  /// Stable FNV-1a (32-bit) hash of [input], returned as a non-negative
  /// integer. Stable across Dart isolates and the web target (the multiply
  /// stays within double precision and the mask truncates to 32 bits on every
  /// platform), unlike `String.hashCode`.
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

/// Lowercase hex encoder for the 16-byte stable id, kept local so the
/// deterministic source ships zero extra dependencies.
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
