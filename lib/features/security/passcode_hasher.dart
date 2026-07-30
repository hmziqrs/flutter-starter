/// Salted one-way hashing for the local passcode. Only the salted hash is
/// persisted; the cleartext is never stored or logged. A future "forgot
/// passcode" path must wipe and force re-setup — never attempt recovery, since
/// a one-way hash has nothing to recover.
library;

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Must be deterministic for a given `(pin, salt)` and never emit the
/// cleartext pin; [generateSalt] must be unique and unpredictable per call.
abstract interface class PasscodeHasher {
  /// Cryptographically-random salt, lowercase hex.
  String generateSalt();

  /// Lowercase-hex SHA-256 digest of `salt || '.' || pin`.
  String saltAndHash(String pin, String salt);
}

/// Production [PasscodeHasher]: 16-byte `Random.secure` salt, SHA-256 over
/// `salt.pin` (the dot delimiter prevents length-extension ambiguity).
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

/// For programmer errors only; the hash computation itself is pure-Dart and
/// cannot fail under `package:crypto`.
final class PasscodeHasherException implements Exception {
  const PasscodeHasherException({required this.operation});

  final String operation;

  @override
  String toString() => 'PasscodeHasherException: $operation failed';
}

/// Unlike `secureStoreProvider`, defaults to the real [CryptoPasscodeHasher]
/// (hashing has no backend to wire). Tests override with a deterministic stub.
final passcodeHasherProvider = Provider<PasscodeHasher>(
  (ref) => const CryptoPasscodeHasher(),
);
