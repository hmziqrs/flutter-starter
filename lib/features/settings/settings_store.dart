abstract interface class SettingsStore {
  Future<String?> readString(String key);

  Future<void> writeString(String key, String value);

  Future<void> remove(String key);
}

final class SettingsStoreException implements Exception {
  const SettingsStoreException({required this.operation, required this.key});

  final String operation;
  final String key;

  @override
  String toString() => 'SettingsStoreException: $operation failed for $key';
}
