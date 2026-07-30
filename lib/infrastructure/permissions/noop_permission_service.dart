import 'package:starter/infrastructure/permissions/permission_service.dart';

/// Deterministic "no permission backend" [PermissionService], selected for
/// web, unsupported platforms, and test/golden runs. Reports
/// [PermissionDenied] (never permanently-denied, so the rationale flow's
/// "continue" path stays exercised in tests) for every probe/request rather
/// than faking a grant.
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
