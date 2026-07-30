import 'package:app_settings/app_settings.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:starter/infrastructure/permissions/permission_service.dart';

/// Production [PermissionService] backed by the `permission_handler` OS
/// plugin (prompts + status reads) and `app_settings` (open system settings —
/// the recovery path for permanently-denied). `permission_handler` types are
/// imported under the `ph` prefix so `ph.PermissionStatus` never collides
/// with this port's typed [PermissionStatus].
///
/// All three methods degrade honestly: a failing request / status read
/// reports [PermissionDenied], and a failing settings launch is swallowed.
class DevicePermissionService implements PermissionService {
  DevicePermissionService();

  @override
  Future<PermissionStatus> requestStatus(AppPermission permission) async {
    try {
      final handler = _mapPermission(permission);
      final result = await handler.request();
      return _mapStatus(result);
    } on Object {
      // Plugin error / missing platform binding — never fake a grant.
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

  /// Order mirrors the plugin's own precedence; an unrecognized value
  /// degrades to [PermissionDenied].
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
    // Unknown / partial / limited states degrade to denied (never a grant).
    return const PermissionDenied();
  }
}
