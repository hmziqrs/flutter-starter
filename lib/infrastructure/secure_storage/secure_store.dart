import 'package:starter/shared/state/operation_exception.dart';

abstract interface class SecureStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

final class SecureStoreException extends OperationException {
  const SecureStoreException({required super.operation, required this.key});

  final String key;

  @override
  String toString() => 'SecureStoreException: $operation failed for $key';
}
