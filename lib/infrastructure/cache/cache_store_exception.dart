import 'package:starter/shared/state/operation_exception.dart';

final class CacheStoreException extends OperationException {
  const CacheStoreException({required super.operation, required this.key});

  final String key;

  @override
  String toString() => 'CacheStoreException: $operation failed for $key';
}
