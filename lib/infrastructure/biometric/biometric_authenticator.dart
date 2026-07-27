import 'package:flutter/foundation.dart';

/// The on-device biometric classes an OS reports as enrolled. Mirrors the
/// subset of `local_auth`'s `BiometricType` that is meaningful across the
/// starter's platforms, exposed as a typed value so the port surface never
/// leaks a plugin type (C2: no widget / port consumer depends on a plugin
/// enum).
enum BiometricKind {
  fingerprint,
  face,
  iris,
  strong,
  weak,
  deviceCredential,
}

/// Structured reason a [BiometricAvailability] report came back unavailable.
///
/// `null` on an available report. Carried so the lock UI and diagnostics can
/// distinguish "no hardware" from "nothing enrolled" without re-reading the
/// plugin (the plugin is never called from a widget).
enum BiometricUnavailableReason {
  /// The platform / device has no biometric feature at all (also the honest
  /// value the `NoopBiometricAuthenticator` reports for web / unsupported
  /// desktop).
  unsupported,

  /// Hardware exists but no biometric is enrolled (or device-level PIN/credential
  /// setup is incomplete).
  notEnrolled,

  /// The availability check itself failed (plugin error / missing platform
  /// binding). Degrades honestly — never fabricates "available".
  unknown,
}

/// Typed availability report produced by [BiometricAuthenticator.checkAvailability].
///
/// Immutable value object. `canCheck` is the single boolean the controller and
/// redirect read to decide whether to gate; `supportedBiometrics`, the optional
/// `reason`, and `requiresSetup` carry detail for diagnostics and the lock UI
/// without forcing those readers to touch the plugin.
@immutable
final class BiometricAvailability {
  const BiometricAvailability._({
    required this.canCheck,
    required this.supportedBiometrics,
    required this.requiresSetup,
    required this.reason,
  });

  /// Builds an available report: hardware is present, enrolled, and ready.
  const BiometricAvailability.available({
    required Set<BiometricKind> supportedBiometrics,
    bool requiresSetup = false,
  }) : this._(
         canCheck: true,
         supportedBiometrics: supportedBiometrics,
         requiresSetup: requiresSetup,
         reason: null,
       );

  /// Builds an unavailable report. [reason] defaults to [BiometricUnavailableReason.unknown]
  /// so a bare `unavailable()` is the honest "we could not confirm biometrics"
  /// outcome rather than an implied "supported but unenrolled".
  const BiometricAvailability.unavailable({
    BiometricUnavailableReason reason = BiometricUnavailableReason.unknown,
    Set<BiometricKind> supportedBiometrics = const <BiometricKind>{},
    bool requiresSetup = false,
  }) : this._(
         canCheck: false,
         supportedBiometrics: supportedBiometrics,
         requiresSetup: requiresSetup,
         reason: reason,
       );

  /// `true` only when the OS reports a ready, enrolled biometric. The sole
  /// field the redirect / controller read to gate.
  final bool canCheck;

  /// The enrolled biometric classes (empty when unavailable).
  final Set<BiometricKind> supportedBiometrics;

  /// `true` when the OS reports biometric hardware present but still requires
  /// the user to complete setup before authentication can proceed.
  final bool requiresSetup;

  /// Why the report is unavailable, or `null` when available.
  final BiometricUnavailableReason? reason;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is BiometricAvailability &&
            canCheck == other.canCheck &&
            requiresSetup == other.requiresSetup &&
            reason == other.reason &&
            _setEquals(supportedBiometrics, other.supportedBiometrics);
  }

  @override
  int get hashCode {
    // XOR is commutative/associative so the set's hash contribution is
    // order-independent (two sets with the same elements hash equally).
    var biometricHash = 0;
    for (final kind in supportedBiometrics) {
      biometricHash ^= kind.hashCode;
    }
    return Object.hash(canCheck, requiresSetup, reason, biometricHash);
  }

  static bool _setEquals(Set<BiometricKind> a, Set<BiometricKind> b) {
    if (a.length != b.length) return false;
    for (final value in a) {
      if (!b.contains(value)) return false;
    }
    return true;
  }
}

/// On-device biometric / device-credential authentication port.
///
/// Mirrors the settings-store port shape: a single-purpose, `Future`-returning
/// surface owned under `lib/infrastructure/`, with a typed exception
/// ([BiometricAuthenticatorException]) and `try/on Object` degradation inside
/// adapters. There is **no** `clearAll`-style bulk call. Backend-free per spec:
/// the production adapter (`LocalAuthAuthenticator`) talks to the OS directly;
/// the deterministic default (`NoopBiometricAuthenticator`) reports unavailable
/// honestly and **never fakes a successful unlock** (C2 / C13).
///
/// Implementations never throw for plugin failures: [checkAvailability] degrades
/// to an unavailable report, and [authenticate] returns `false`. A biometric
/// that cannot be confirmed must never fabricate availability, and a failed
/// prompt must never fabricate success.
abstract interface class BiometricAuthenticator {
  /// Reports the current OS biometric availability. Never throws for plugin
  /// failures — degrades to [BiometricAvailability.unavailable] instead.
  Future<BiometricAvailability> checkAvailability();

  /// Presents the OS biometric prompt with [localizedReason] and returns
  /// `true` only on a confirmed, successful authentication. Returns `false`
  /// for cancellation, failure, or plugin error — never throws, never fakes
  /// success.
  Future<bool> authenticate({required String localizedReason});
}

/// Thrown by [BiometricAuthenticator] implementations only for programmer errors
/// (never for plugin / availability failures, which degrade honestly).
final class BiometricAuthenticatorException implements Exception {
  const BiometricAuthenticatorException({required this.operation});

  final String operation;

  @override
  String toString() => 'BiometricAuthenticatorException: $operation failed';
}

/// The biometric lock's public state, owned by `BiometricUnlockController` and
/// read by the C5 redirect.
///
/// Exhaustive `switch` over the three subtypes is required at every call site
/// (the redirect predicate, the dev-gallery fixtures, and the lock page) so
/// every branch is handled explicitly. The redirect acts only on
/// [BiometricLockLocked]; the lock page renders [BiometricLockLocked] and
/// [BiometricLockUnavailable] differently; [BiometricLockUnlocked] clears the
/// gate.
sealed class BiometricLockState {
  const BiometricLockState();
}

/// No biometric gate is active (either disabled in settings or already
/// unlocked this session). Clears the redirect — protected routes are reachable.
final class BiometricLockUnlocked extends BiometricLockState {
  const BiometricLockUnlocked();
}

/// App entry is gated behind a biometric prompt. The redirect sends protected
/// shell destinations to `AppRoutes.biometricLockPath`; the lock page presents
/// the unlock action.
final class BiometricLockLocked extends BiometricLockState {
  const BiometricLockLocked();
}

/// Biometric gating is enabled but the OS reports no usable biometric (no
/// hardware, nothing enrolled, or the availability check failed). The lock
/// page surfaces the unavailable body and the device-credential / PIN fallback
/// seam rather than a prompt that can never succeed.
final class BiometricLockUnavailable extends BiometricLockState {
  const BiometricLockUnavailable();
}
