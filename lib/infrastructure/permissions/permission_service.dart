import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/shared/state/operation_exception.dart';

enum AppPermission {
  camera,
  photos,
  location,
}

sealed class PermissionStatus {
  const PermissionStatus._();

  bool get isGranted => false;

  bool get isPermanentlyDenied => false;
}

final class PermissionGranted extends PermissionStatus {
  const PermissionGranted() : super._();

  @override
  bool get isGranted => true;
}

final class PermissionDenied extends PermissionStatus {
  const PermissionDenied() : super._();
}

final class PermissionPermanentlyDenied extends PermissionStatus {
  const PermissionPermanentlyDenied() : super._();

  @override
  bool get isPermanentlyDenied => true;
}

final class PermissionRestricted extends PermissionStatus {
  const PermissionRestricted() : super._();
}

abstract interface class PermissionService {
  Future<PermissionStatus> requestStatus(AppPermission permission);

  Future<PermissionStatus> checkStatus(AppPermission permission);

  Future<void> openSystemSettings();
}

final class PermissionServiceException extends OperationException {
  const PermissionServiceException({required super.operation, required this.permission});

  final AppPermission permission;

  @override
  String toString() => 'PermissionServiceException: $operation failed for ${permission.name}';
}

final permissionServiceProvider = Provider<PermissionService>(
  (ref) => throw StateError('PermissionService must be overridden at the composition root.'),
);

String permissionDebugLabel(AppPermission permission) {
  return switch (permission) {
    AppPermission.camera => 'camera',
    AppPermission.photos => 'photos',
    AppPermission.location => 'location',
  };
}

@visibleForTesting
const permissionStatusVariants = <PermissionStatus>[
  PermissionGranted(),
  PermissionDenied(),
  PermissionPermanentlyDenied(),
  PermissionRestricted(),
];
