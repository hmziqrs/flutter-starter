base class OperationException implements Exception {
  const OperationException({required this.operation, this.detail});

  final String operation;

  final String? detail;

  @override
  String toString() => detail == null ? '$operation failed' : '$operation failed: $detail';
}
