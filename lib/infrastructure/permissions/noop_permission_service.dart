import 'package:starter/infrastructure/permissions/permission_service.dart';

/// Deterministic, honest "no permission backend" [PermissionService].
///
/// The composition root selects this adapter for web, unsupported platforms,
/// and integration-test / golden runs (keyed off `PlatformCapabilities`, never a
/// global) so the starter stays green and goldens stay stable without ever
/// triggering the OS permission prompt. Per the no-backend / honest-feedback
/// contracts (C2 / C13) it reports [PermissionDenied] for every probe and
/// request — it **never fakes a grant** — and `openSystemSettings` is a silent
/// no-op (there is no platform settings page to open in the hermetic harness).
///
/// There is no permanently-denied lie here either: returning denied (not
/// permanently-denied) keeps the rationale flow's "continue" path exercised in
/// tests, which is the honest representation of a platform that simply has no
/// prompt to show.
class NoopPermissionService implements PermissionService {
  const NoopPermissionService();

  @override
  Future<PermissionStatus> requestStatus(AppPermission permission) async {
    // Honest: no backend, no grant. Never fake success.
    return const PermissionDenied();
  }

  @override
  Future<PermissionStatus> checkStatus(AppPermission permission) async {
    return const PermissionDenied();
  }

  @override
  Future<void> openSystemSettings() async {
    // No platform settings surface in the hermetic harness — silent no-op.
  }
}
