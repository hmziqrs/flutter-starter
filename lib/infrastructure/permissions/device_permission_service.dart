import 'package:app_settings/app_settings.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:starter/infrastructure/logging/app_logger.dart';
import 'package:starter/infrastructure/permissions/permission_service.dart';
import 'package:starter/shared/async/run_guarded.dart';

class DevicePermissionService implements PermissionService {
  DevicePermissionService({AppLogger? logger}) : _logger = logger ?? AppLogger.bootstrap();

  final AppLogger _logger;

  @override
  Future<PermissionStatus> requestStatus(AppPermission permission) async {
    try {
      final handler = _mapPermission(permission);
      final result = await handler.request();
      return _mapStatus(result);
    } on Object catch (error, stackTrace) {
      _logger.warning(
        'permissions.request_failed',
        error: error,
        stackTrace: stackTrace,
        context: {'permission': permission.name},
      );
      return const PermissionDenied();
    }
  }

  @override
  Future<PermissionStatus> checkStatus(AppPermission permission) async {
    try {
      final handler = _mapPermission(permission);
      final result = await handler.status;
      return _mapStatus(result);
    } on Object catch (error, stackTrace) {
      _logger.warning(
        'permissions.check_failed',
        error: error,
        stackTrace: stackTrace,
        context: {'permission': permission.name},
      );
      return const PermissionDenied();
    }
  }

  @override
  Future<void> openSystemSettings() async {
    await runGuarded(
      AppSettings.openAppSettings,
      logger: _logger,
      label: 'permissions.open_settings',
    );
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
