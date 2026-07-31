abstract interface class SecureStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

final class SecureStoreException implements Exception {
  const SecureStoreException({required this.operation, required this.key});

  final String operation;
  final String key;

  @override
  String toString() => 'SecureStoreException: $operation failed for $key';
}
