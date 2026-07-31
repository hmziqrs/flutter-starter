import 'package:flutter/foundation.dart';

enum BiometricKind {
  fingerprint,
  face,
  iris,
  strong,
  weak,
  deviceCredential,
}

enum BiometricUnavailableReason {
  unsupported,

  notEnrolled,

  unknown,
}

@immutable
final class BiometricAvailability {
  const BiometricAvailability._({
    required this.canCheck,
    required this.supportedBiometrics,
    required this.requiresSetup,
    required this.reason,
  });

  const BiometricAvailability.available({
    required Set<BiometricKind> supportedBiometrics,
    bool requiresSetup = false,
  }) : this._(
         canCheck: true,
         supportedBiometrics: supportedBiometrics,
         requiresSetup: requiresSetup,
         reason: null,
       );

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

  final bool canCheck;

  final Set<BiometricKind> supportedBiometrics;

  final bool requiresSetup;

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

/// [authenticate] never throws on plugin failure and never fabricates success.
abstract interface class BiometricAuthenticator {
  Future<BiometricAvailability> checkAvailability();

  Future<bool> authenticate({required String localizedReason});
}

final class BiometricAuthenticatorException implements Exception {
  const BiometricAuthenticatorException({required this.operation});

  final String operation;

  @override
  String toString() => 'BiometricAuthenticatorException: $operation failed';
}

sealed class BiometricLockState {
  const BiometricLockState();
}

final class BiometricLockUnlocked extends BiometricLockState {
  const BiometricLockUnlocked();
}

final class BiometricLockLocked extends BiometricLockState {
  const BiometricLockLocked();
}

final class BiometricLockUnavailable extends BiometricLockState {
  const BiometricLockUnavailable();
}
