import 'package:starter/infrastructure/cache/cache_store.dart';

/// One row of the optional cache diagnostics dump.
///
/// Lives behind `developmentToolsEnabled` on DiagnosticsPage (the wiring is
/// optional and described in this feature's manifest). Kept narrow to respect
/// the per-key port discipline: the dump reports presence + age only — it does
/// not enumerate unknown keys (no `keys()` on [CacheStore], no `clearAll`) and
/// does not report payload size (the port exposes no byte accessor). The caller
/// supplies the known key set it wants to inspect.
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
///
/// Each row is one [CacheDiagnosticRow]; absent keys produce
/// `present: false, age: null`. Never throws — a per-key storage failure is
/// reported as absent so the dump never tears down the diagnostics page. The
/// consuming feature calls this from its DiagnosticsPage trigger with the key
/// set it owns.
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
