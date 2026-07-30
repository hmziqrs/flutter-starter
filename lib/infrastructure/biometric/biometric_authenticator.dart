import 'package:flutter/foundation.dart';

/// The on-device biometric classes an OS reports as enrolled. Mirrors the
/// subset of `local_auth`'s `BiometricType` relevant to this app's platforms,
/// so the port surface never leaks the plugin's own enum.
enum BiometricKind {
  fingerprint,
  face,
  iris,
  strong,
  weak,
  deviceCredential,
}

/// Why a [BiometricAvailability] report came back unavailable. `null` on an
/// available report.
enum BiometricUnavailableReason {
  /// No biometric feature at all (also reported by `NoopBiometricAuthenticator`
  /// for web / unsupported desktop).
  unsupported,

  /// Hardware exists but nothing is enrolled (or PIN/credential setup is
  /// incomplete).
  notEnrolled,

  /// The availability check itself failed (plugin error / missing platform
  /// binding).
  unknown,
}

/// Typed availability report produced by [BiometricAuthenticator.checkAvailability].
@immutable
final class BiometricAvailability {
  const BiometricAvailability._({
    required this.canCheck,
    required this.supportedBiometrics,
    required this.requiresSetup,
    required this.reason,
  });

  /// Hardware is present, enrolled, and ready.
  const BiometricAvailability.available({
    required Set<BiometricKind> supportedBiometrics,
    bool requiresSetup = false,
  }) : this._(
         canCheck: true,
         supportedBiometrics: supportedBiometrics,
         requiresSetup: requiresSetup,
         reason: null,
       );

  /// [reason] defaults to [BiometricUnavailableReason.unknown] — "could not
  /// confirm" rather than implying "supported but unenrolled".
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

  /// `true` only when the OS reports a ready, enrolled biometric.
  final bool canCheck;

  /// The enrolled biometric classes (empty when unavailable).
  final Set<BiometricKind> supportedBiometrics;

  /// `true` when hardware is present but the user must still complete setup.
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
    // XOR keeps the set's hash contribution order-independent.
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
/// Implementations never throw for plugin failures: [checkAvailability]
/// degrades to an unavailable report, and [authenticate] returns `false`
/// rather than fabricating success.
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

/// Thrown by [BiometricAuthenticator] implementations only for programmer
/// errors (never for plugin / availability failures, which degrade instead).
final class BiometricAuthenticatorException implements Exception {
  const BiometricAuthenticatorException({required this.operation});

  final String operation;

  @override
  String toString() => 'BiometricAuthenticatorException: $operation failed';
}

/// The biometric lock's public state, owned by `BiometricUnlockController` and
/// read by the redirect. Exhaustively switched over at every call site.
sealed class BiometricLockState {
  const BiometricLockState();
}

/// No gate active (disabled in settings, or already unlocked this session).
final class BiometricLockUnlocked extends BiometricLockState {
  const BiometricLockUnlocked();
}

/// App entry is gated behind a biometric prompt.
final class BiometricLockLocked extends BiometricLockState {
  const BiometricLockLocked();
}

/// Gating is enabled but the OS reports no usable biometric (no hardware,
/// nothing enrolled, or the check failed); the lock page shows a fallback.
final class BiometricLockUnavailable extends BiometricLockState {
  const BiometricLockUnavailable();
}
