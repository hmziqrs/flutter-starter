import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/shared/state/operation_exception.dart';

enum HapticKind {
  selection,
  impactLight,
  impactMedium,
  impactHeavy,
  notificationSuccess,
  notificationWarning,
  notificationError,
}

// ignore: one_member_abstracts, multi-implementation port
abstract interface class HapticService {
  Future<void> trigger(HapticKind kind);
}

final class HapticServiceException extends OperationException {
  const HapticServiceException({required super.operation, required this.kind});

  final HapticKind kind;

  @override
  String toString() => 'HapticServiceException: $operation failed for ${kind.name}';
}

final hapticServiceProvider = Provider<HapticService>(
  (ref) => throw StateError('HapticService must be overridden at the composition root.'),
);
