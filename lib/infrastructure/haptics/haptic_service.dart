import 'package:flutter_riverpod/flutter_riverpod.dart';

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

final class HapticServiceException implements Exception {
  const HapticServiceException({required this.operation, required this.kind});

  final String operation;
  final HapticKind kind;

  @override
  String toString() => 'HapticServiceException: $operation failed for ${kind.name}';
}

final hapticServiceProvider = Provider<HapticService>(
  (ref) => throw StateError('HapticService must be overridden at the composition root.'),
);
