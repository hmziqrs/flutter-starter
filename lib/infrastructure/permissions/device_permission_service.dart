import 'package:app_settings/app_settings.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:starter/infrastructure/permissions/permission_service.dart';

/// Production [PermissionService] backed by the `permission_handler` OS plugin
/// (permission prompts + status reads) and `app_settings` (open the system
/// settings page — the recovery path for permanently-denied).
///
/// Constructed in `AppDependencies.production` (the composition root) only on
/// supported platforms; web / integration-test runs use `NoopPermissionService`
/// instead, selected from `PlatformCapabilities`. Neither plugin is referenced
/// outside this adapter — every consumer reads the typed [PermissionStatus]
/// surface (C2: no widget calls a plugin directly). The `permission_handler`
/// types are imported under the `ph` prefix so the plugin's own
/// `ph.PermissionStatus` never collides with this port's typed
/// [PermissionStatus].
///
/// All three methods degrade honestly inside `try/on Object` (C13: never fake
/// success): a failing request / status read reports [PermissionDenied], and a
/// failing settings launch is swallowed. The plugin's `ph.PermissionStatus` is
/// mapped exhaustively to the typed sealed hierarchy so the port surface never
/// leaks a plugin enum, and a future plugin value degrades to [PermissionDenied]
/// rather than coercing a wrong grant.
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

  /// Maps the typed [AppPermission] to the `permission_handler` [ph.Permission].
  /// Exhaustive — a new kind here requires a new branch (and a new
  /// permission_handler entry) so a typo cannot silently fall through to a
  /// wrong permission.
  static ph.Permission _mapPermission(AppPermission permission) {
    return switch (permission) {
      AppPermission.camera => ph.Permission.camera,
      AppPermission.photos => ph.Permission.photos,
      AppPermission.location => ph.Permission.location,
    };
  }

  /// Maps the plugin status to the typed sealed hierarchy. `permission_handler`
  /// exposes boolean accessors (`isGranted` / `isDenied` / `isPermanentlyDenied`
  /// / `isRestricted`) that are mutually exclusive in practice; the order below
  /// mirrors the plugin's own precedence. An unrecognized value degrades to
  /// [PermissionDenied] — never to a grant.
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
