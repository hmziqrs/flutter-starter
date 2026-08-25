import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/shared/state/operation_exception.dart';

abstract interface class PasscodeHasher {
  String generateSalt();

  String saltAndHash(String pin, String salt);
}

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

final class PasscodeHasherException extends OperationException {
  const PasscodeHasherException({required super.operation});

  @override
  String toString() => 'PasscodeHasherException: $operation failed';
}

final passcodeHasherProvider = Provider<PasscodeHasher>(
  (ref) => const CryptoPasscodeHasher(),
);
