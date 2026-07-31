final class CacheStoreException implements Exception {
  const CacheStoreException({required this.operation, required this.key});

  final String operation;

  final String key;

  @override
  String toString() => 'CacheStoreException: $operation failed for $key';
}
