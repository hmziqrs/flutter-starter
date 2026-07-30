/// Thrown by `CacheStore` implementations when an underlying read / write /
/// remove / age operation fails. The original platform or I/O error is
/// intentionally not exposed.
final class CacheStoreException implements Exception {
  const CacheStoreException({required this.operation, required this.key});

  /// The operation that failed: `read`, `write`, `remove`, or `age`.
  final String operation;

  /// The cache key the operation targeted.
  final String key;

  @override
  String toString() => 'CacheStoreException: $operation failed for $key';
}
