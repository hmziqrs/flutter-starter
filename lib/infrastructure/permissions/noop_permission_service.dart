import 'package:starter/infrastructure/permissions/permission_service.dart';

class NoopPermissionService implements PermissionService {
  const NoopPermissionService();

  @override
  Future<PermissionStatus> requestStatus(AppPermission permission) async =>
      const PermissionDenied();

  @override
  Future<PermissionStatus> checkStatus(AppPermission permission) async => const PermissionDenied();

  @override
  Future<void> openSystemSettings() async {}
}
