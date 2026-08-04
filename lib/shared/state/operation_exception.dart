/// Shared base for operation-string service exceptions.
///
/// Service ports across the app throw exceptions that all carry an [operation]
/// label (e.g. `'read'`, `'track'`) and optionally a [detail] string, and they
/// all format themselves the same way. Subclasses extend this base instead of
/// redeclaring the [operation] field and a [toString] template. Subclasses that
/// carry an additional identifying field (a key, permission, kind, ...) keep
/// that field and may override [toString] to append it.
base class OperationException implements Exception {
  const OperationException({required this.operation, this.detail});

  /// Logical operation that failed, e.g. `'read'` or `'track'`.
  final String operation;

  /// Optional human-readable detail appended to [toString].
  final String? detail;

  @override
  String toString() => detail == null ? '$operation failed' : '$operation failed: $detail';
}
