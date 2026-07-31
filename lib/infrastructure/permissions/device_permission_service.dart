import 'package:app_settings/app_settings.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:starter/infrastructure/permissions/permission_service.dart';

class DevicePermissionService implements PermissionService {
  DevicePermissionService();

  @override
  Future<PermissionStatus> requestStatus(AppPermission permission) async {
    try {
      final handler = _mapPermission(permission);
      final result = await handler.request();
      return _mapStatus(result);
    } on Object {
      return const PermissionDenied();
    }
  }

  @override
  Future<PermissionStatus> checkStatus(AppPermission permission) async {
    try {
      final handler = _mapPermission(permission);
      final result = await handler.status;
      return _mapStatus(result);
    } on Object {
      return const PermissionDenied();
    }
  }

  @override
  Future<void> openSystemSettings() async {
    try {
      await AppSettings.openAppSettings();
    } on Object {
      // Best-effort: a failure to launch settings never gates a user action.
    }
  }

  static ph.Permission _mapPermission(AppPermission permission) {
    return switch (permission) {
      AppPermission.camera => ph.Permission.camera,
      AppPermission.photos => ph.Permission.photos,
      AppPermission.location => ph.Permission.location,
    };
  }

  static PermissionStatus _mapStatus(ph.PermissionStatus status) {
    if (status.isGranted) {
      return const PermissionGranted();
    } else if (status.isPermanentlyDenied) {
      return const PermissionPermanentlyDenied();
    } else if (status.isRestricted) {
      return const PermissionRestricted();
    } else if (status.isDenied) {
      return const PermissionDenied();
    }
    return const PermissionDenied();
  }
}
