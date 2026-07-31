import 'package:starter/infrastructure/cache/cache_store.dart';

final class CacheDiagnosticRow {
  const CacheDiagnosticRow({required this.key, required this.age, required this.present});

  final String key;

  final Duration? age;

  final bool present;

  @override
  String toString() =>
      'CacheDiagnosticRow(key: $key, present: $present, age: ${age?.inSeconds ?? '-'}s)';
}

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
