import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The device permission kinds the starter requests at runtime.
///
/// OS notification permission is owned by the push-notifications feature
/// (`NotificationsRepository.requestPermission`), not this port.
enum AppPermission {
  camera,
  photos,
  location,
}

/// Typed outcome of a permission probe / request.
///
/// Sealed (not a raw enum) so every call site exhaustively switches over the
/// four OS states rather than falling into a `default` — the common source of
/// permission bugs is treating "permanently denied" as plain "denied".
sealed class PermissionStatus {
  const PermissionStatus._();

  /// `true` only for [PermissionGranted].
  bool get isGranted => false;

  /// `true` only for [PermissionPermanentlyDenied] — re-prompting is a no-op;
  /// the only recovery path is system settings.
  bool get isPermanentlyDenied => false;
}

/// The OS granted the permission (or it was already granted). Proceed.
final class PermissionGranted extends PermissionStatus {
  const PermissionGranted() : super._();

  @override
  bool get isGranted => true;
}

/// The OS denied the request this round (or it was never asked). A re-prompt is
/// still meaningful, so the rationale flow may surface the sheet again.
final class PermissionDenied extends PermissionStatus {
  const PermissionDenied() : super._();
}

/// The user picked "Don't ask again" (Android) or the resource is fully blocked
/// (iOS). Re-prompting is a no-op — route to `openSystemSettings()` instead.
final class PermissionPermanentlyDenied extends PermissionStatus {
  const PermissionPermanentlyDenied() : super._();

  @override
  bool get isPermanentlyDenied => true;
}

/// The resource is restricted by policy (e.g. parental controls / MDM). Treated
/// like denied for UX purposes but kept distinct so diagnostics can report it.
final class PermissionRestricted extends PermissionStatus {
  const PermissionRestricted() : super._();
}

/// Runtime-permission port. No `clearAll`-style bulk call — the OS owns
/// permission state and no app-side cache may drift from it. Production
/// adapter (`DevicePermissionService`) uses `permission_handler`; the noop
/// default reports [PermissionDenied] honestly, never a fake grant.
abstract interface class PermissionService {
  /// Triggers the OS permission prompt for [permission]. Never throws for
  /// plugin failures — degrades to [PermissionDenied].
  Future<PermissionStatus> requestStatus(AppPermission permission);

  /// Reads the current OS state without prompting. Used by the rationale flow
  /// to decide "continue" (request) vs "open settings" (permanently denied).
  Future<PermissionStatus> checkStatus(AppPermission permission);

  /// Opens the system settings page for this app (recovery path for
  /// [PermissionPermanentlyDenied]). Best-effort; failures are swallowed.
  Future<void> openSystemSettings();
}

/// Thrown by [PermissionService] adapters only for programmer errors (never
/// for plugin / permission failures, which degrade to a denied status).
final class PermissionServiceException implements Exception {
  const PermissionServiceException({required this.operation, required this.permission});

  final String operation;
  final AppPermission permission;

  @override
  String toString() => 'PermissionServiceException: $operation failed for ${permission.name}';
}

/// Throws a [StateError] until the composition root overrides it with a
/// concrete adapter (`DevicePermissionService` on native, `NoopPermissionService`
/// for web / integration tests).
final permissionServiceProvider = Provider<PermissionService>(
  (ref) => throw StateError('PermissionService must be overridden at the composition root.'),
);

/// Maps an [AppPermission] to a stable label for diagnostics / analytics.
String permissionDebugLabel(AppPermission permission) {
  return switch (permission) {
    AppPermission.camera => 'camera',
    AppPermission.photos => 'photos',
    AppPermission.location => 'location',
  };
}

/// Every [PermissionStatus] variant, for tests / fixtures.
@visibleForTesting
const permissionStatusVariants = <PermissionStatus>[
  PermissionGranted(),
  PermissionDenied(),
  PermissionPermanentlyDenied(),
  PermissionRestricted(),
];
