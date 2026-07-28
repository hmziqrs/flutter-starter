/// Salted one-way hashing for the local app passcode (pin-autolock).
///
/// The passcode is a **local-only** defense-in-depth gate: it never leaves the
/// device and there is no backend (the feature is backend-free per spec). Only
/// a **salted hash** is persisted (via `SecureStore`); the cleartext is never
/// stored and never logged (the `LogRedactor`'s `_sensitiveAssignment` regex
/// already scrubs `passcode=...`, and the controller never puts the raw value
/// into a context map or log line).
///
/// The interface mirrors the settings-store port shape (a single-purpose
/// surface owned under the feature), but the production default is **real** —
/// [CryptoPasscodeHasher] wraps `package:crypto`'s `sha256` with a
/// cryptographically-random salt. There is no Noop: hashing is a pure-Dart
/// computation with no backend, so the real implementation IS the default (the
/// no-backend rule applies to actions that would fake a remote success; a local
/// hash has nothing to fake).
///
/// Hash, never encrypt-and-store. If a future "forgot passcode" path is added
/// it must **wipe** the salt/hash (forcing re-setup) — it must never recover the
/// cleartext, because there is nothing to recover from a one-way hash.
library;

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pure-Dart salted-hash interface for the local passcode.
///
/// Implementations must be deterministic for a given `(pin, salt)` pair and
/// must never emit the cleartext pin in any form (return value, exception, or
/// log). [generateSalt] must produce a unique, unpredictable salt per call so
/// two users with the same passcode store distinct hashes.
abstract interface class PasscodeHasher {
  /// Returns a freshly-generated, cryptographically-random salt encoded as
  /// lowercase hex. Each call returns a new value.
  String generateSalt();

  /// Returns the lowercase-hex SHA-256 digest of `salt || '.' || pin`.
  ///
  /// Deterministic for a given `(pin, salt)`. Never returns or retains the
  /// cleartext [pin]; the digest is one-way.
  String saltAndHash(String pin, String salt);
}

/// Production [PasscodeHasher] backed by `package:crypto`.
///
/// The salt is 16 bytes from `Random.secure` (the platform CSPRNG), hex-encoded
/// so it round-trips through `SecureStore` as plain ASCII. The hash is
/// SHA-256 over the UTF-8 bytes of `salt.pin`; the dot delimiter prevents
/// length-extension ambiguity between the salt and pin portions.
final class CryptoPasscodeHasher implements PasscodeHasher {
  const CryptoPasscodeHasher({Random Function()? secureRandomFactory})
    : _secureRandomFactory = secureRandomFactory ?? _defaultSecureRandom;

  final Random Function() _secureRandomFactory;

  @override
  String generateSalt() {
    final bytes = List<int>.generate(_saltByteLength, (_) => _secureRandomFactory().nextInt(256));
    return bytes.map(_toHex).join();
  }

  @override
  String saltAndHash(String pin, String salt) {
    final digest = sha256.convert(utf8.encode('$salt.$pin'));
    return digest.toString();
  }

  static const int _saltByteLength = 16;

  static Random _defaultSecureRandom() => Random.secure();

  static String _toHex(int byte) => byte.toRadixString(16).padLeft(2, '0');
}

/// Thrown by [PasscodeHasher] implementations only for programmer errors
/// (never for the hash computation itself, which is pure-Dart and cannot fail
/// honestly under `package:crypto`). Kept for API symmetry with the other
/// feature ports so a future impl can degrade through a typed exception.
final class PasscodeHasherException implements Exception {
  const PasscodeHasherException({required this.operation});

  final String operation;

  @override
  String toString() => 'PasscodeHasherException: $operation failed';
}

/// Handwritten Riverpod handle for the [PasscodeHasher] port.
///
/// Unlike `secureStoreProvider` (which throws until the composition root
/// overrides it), this provider returns the **real** [CryptoPasscodeHasher] by
/// default: hashing is a pure-Dart computation with no backend to wire, so the
/// real implementation is the no-backend default (C2: the rule is about never
/// faking a remote success — a local hash has nothing to fake). Tests override
/// with a deterministic stub to assert `(pin, salt)` determinism without
/// reaching the platform CSPRNG.
final passcodeHasherProvider = Provider<PasscodeHasher>(
  (ref) => const CryptoPasscodeHasher(),
);
