import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:starter/features/experiments/experiment_key.dart';
import 'package:starter/features/experiments/experiment_source.dart';
import 'package:starter/features/experiments/experiment_variant.dart';
import 'package:starter/features/settings/settings_store.dart';

/// FNV-1a, not `String.hashCode` (unstable on web/isolates).
final class DeterministicExperimentSource implements ExperimentSource {
  DeterministicExperimentSource({
    required this.store,
    this.salt = defaultSalt,
    this.stableIdKey = defaultStableIdKey,
    Random? randomSeed,
  }) : random = randomSeed ?? Random.secure();

  static const defaultStableIdKey = 'experiments.deviceStableId';

  static const defaultSalt = 'starter.abex.v1';

  final SettingsStore store;

  final String salt;

  final String stableIdKey;

  final Random random;

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

  String _generateId() {
    final bytes = Uint8List(16);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return _toHex(bytes);
  }

  @visibleForTesting
  ExperimentVariant bucket(ExperimentKey key, String stableId) => _bucket(key, stableId);

  // Changing the hash or salt re-buckets every user — bump deliberately.
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
    return const ExperimentVariantControl();
  }

  static int _fnv1a32(String input) {
    const offsetBasis = 0x811c9dc5;
    const prime = 0x01000193;
    const mask = 0xFFFFFFFF;
    var hash = offsetBasis;
    for (final byte in utf8.encode(input)) {
      hash ^= byte;
      hash = (hash * prime) & mask;
    }
    return hash & 0x7FFFFFFF;
  }
}

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
