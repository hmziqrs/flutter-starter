import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The device permission kinds the starter requests at runtime.
///
/// A closed, typed enum so the port surface never leaks a plugin type and every
/// consumer handles the full set via an exhaustive `switch` (no `default`). The
/// OS notification-permission request is intentionally absent — it is owned by
/// the push-notifications feature (`NotificationsRepository.requestPermission`),
/// not this port. Add a kind here only when a new protected resource needs a
/// runtime prompt, and update every exhaustive switch at once.
enum AppPermission {
  camera,
  photos,
  location,
}

/// Typed outcome of a permission probe / request.
///
/// A sealed class (not a raw enum) so every call site is forced into an
/// exhaustive `switch` over the four OS states — there is no `default` escape
/// hatch, which is the single most common source of permission bugs (silently
/// treating "permanently denied" as "denied" and re-prompting a one-way door).
/// The two boolean accessors cover the only branches the rationale flow reads:
/// [isGranted] (proceed to pick) and [isPermanentlyDenied] (route to system
/// settings, never re-prompt).
sealed class PermissionStatus {
  const PermissionStatus._();

  /// `true` only for [PermissionGranted].
  bool get isGranted => false;

  /// `true` only for [PermissionPermanentlyDenied] — the one-way-door state
  /// where re-prompting is a no-op and the only recovery path is system settings.
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

/// Runtime-permission port.
///
/// Mirrors the `SettingsStore` port shape: a single-purpose, `Future`-returning
/// surface owned under `lib/infrastructure/`, with a typed exception
/// ([PermissionServiceException]) and `try/on Object` degradation inside the
/// adapters. There is **no** `clearAll`-style bulk call — the OS owns permission
/// state, and no app-side cache is permitted to drift from it (see the feature
/// spec's Risks section).
///
/// Backend-free per the no-backend contract (C2 / C13): the production adapter
/// (`DevicePermissionService`) talks to the OS via `permission_handler`; the
/// deterministic default (`NoopPermissionService`) reports [PermissionDenied]
/// honestly and **never fakes a grant**. The rationale flow always shows the
/// sheet *before* calling [requestStatus] — stores reject apps that request
/// without context, and a rationale step prevents silent permanent denials.
abstract interface class PermissionService {
  /// Triggers the OS permission prompt for [permission] and returns the
  /// resolved [PermissionStatus]. On a platform without the prompt (the noop
  /// default), this returns [PermissionDenied] honestly — never a grant.
  ///
  /// Adapters never throw for plugin failures: a failing request degrades to
  /// [PermissionDenied] rather than surfacing an error to the UI.
  Future<PermissionStatus> requestStatus(AppPermission permission);

  /// Reads the current OS permission state without showing a prompt. Used by
  /// the rationale flow to decide whether to offer "continue" (request) vs
  /// "open settings" (permanently denied). Degrades to [PermissionDenied].
  Future<PermissionStatus> checkStatus(AppPermission permission);

  /// Opens the system settings page for this app (the recovery path for
  /// [PermissionPermanentlyDenied]). Best-effort: a failure is swallowed and
  /// never gates a user action. The actual launch is delegated to `app_settings`
  /// by `DevicePermissionService`; the noop default is a silent no-op.
  Future<void> openSystemSettings();
}

/// Thrown by [PermissionService] adapters only for programmer errors (never for
/// plugin / permission failures, which degrade honestly to a denied status).
final class PermissionServiceException implements Exception {
  const PermissionServiceException({required this.operation, required this.permission});

  final String operation;
  final AppPermission permission;

  @override
  String toString() => 'PermissionServiceException: $operation failed for ${permission.name}';
}

/// Handwritten Riverpod handle for the [PermissionService] port.
///
/// Mirrors `settingsRepositoryProvider` / `biometricAuthenticatorProvider` /
/// `hapticServiceProvider`: it throws a [StateError] until the composition root
/// overrides it with a concrete adapter. The composition root selects
/// `DevicePermissionService` on supported native platforms or the honest
/// `NoopPermissionService` for web / integration-test runs (selected from
/// `PlatformCapabilities` in `AppDependencies.production`, never via a global),
/// and wires the override in `lib/app/app.dart` as a peer of the other port
/// overrides.
final permissionServiceProvider = Provider<PermissionService>(
  (ref) => throw StateError('PermissionService must be overridden at the composition root.'),
);

/// Maps an [AppPermission] to a stable label for diagnostics / analytics. Kept
/// here so every consumer renders the same redacted string (never a plugin
/// identifier). Exhaustive over [AppPermission].
String permissionDebugLabel(AppPermission permission) {
  return switch (permission) {
    AppPermission.camera => 'camera',
    AppPermission.photos => 'photos',
    AppPermission.location => 'location',
  };
}

/// Provided for tests / fixtures that need an immutable [PermissionStatus] set
/// covering every variant. Asserts the sealed hierarchy has exactly four
/// subtypes so a future addition is caught here rather than at a call site.
@visibleForTesting
const permissionStatusVariants = <PermissionStatus>[
  PermissionGranted(),
  PermissionDenied(),
  PermissionPermanentlyDenied(),
  PermissionRestricted(),
];
