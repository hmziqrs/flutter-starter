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

// One-member abstract lint is a false positive for a multi-implementation port.
// ignore: one_member_abstracts
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
