import 'package:flutter_riverpod/flutter_riverpod.dart';

enum UpdateAvailability {
  noUpdate,

  available,

  required,
}

abstract interface class AppUpdateService {
  Future<UpdateAvailability> checkForUpdate();

  Future<void> launchUpdate({bool immediate = false});
}

final class AppUpdateServiceException implements Exception {
  const AppUpdateServiceException({required this.operation});

  final String operation;

  @override
  String toString() => 'AppUpdateServiceException: $operation failed';
}

final appUpdateServiceProvider = Provider<AppUpdateService>(
  (ref) => throw StateError('AppUpdateService must be overridden at the composition root.'),
);
