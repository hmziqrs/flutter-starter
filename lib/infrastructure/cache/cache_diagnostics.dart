import 'package:starter/infrastructure/cache/cache_store.dart';

/// One row of the optional cache diagnostics dump (behind
/// `developmentToolsEnabled`). Reports presence + age only — no key
/// enumeration or payload size; the caller supplies the known key set.
final class CacheDiagnosticRow {
  const CacheDiagnosticRow({required this.key, required this.age, required this.present});

  /// The cache key this row describes.
  final String key;

  /// Elapsed since the entry was fetched, or `null` when absent.
  final Duration? age;

  /// Whether a cache entry exists for [key].
  final bool present;

  @override
  String toString() =>
      'CacheDiagnosticRow(key: $key, present: $present, age: ${age?.inSeconds ?? '-'}s)';
}

/// Builds a diagnostics snapshot for the given [keys] by reading [store].age.
/// Never throws — a per-key storage failure is reported as absent.
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
