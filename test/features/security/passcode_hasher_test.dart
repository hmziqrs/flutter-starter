import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/security/passcode_hasher.dart';

void main() {
  group('CryptoPasscodeHasher', () {
    test('salt is unique per call', () {
      const hasher = CryptoPasscodeHasher();
      final salts = <String>{
        for (var i = 0; i < 64; i++) hasher.generateSalt(),
      };
      expect(salts.length, 64);
    });

    test('salt is lowercase hex of the expected length', () {
      const hasher = CryptoPasscodeHasher();
      final salt = hasher.generateSalt();
      expect(salt.length, 32);
      expect(RegExp(r'^[0-9a-f]{32}$').hasMatch(salt), isTrue);
    });

    test('hash is deterministic for the same (pin, salt)', () {
      const hasher = CryptoPasscodeHasher();
      const pin = '1234';
      final salt = hasher.generateSalt();
      expect(hasher.saltAndHash(pin, salt), hasher.saltAndHash(pin, salt));
    });

    test('hash differs for different pins (same salt)', () {
      const hasher = CryptoPasscodeHasher();
      final salt = hasher.generateSalt();
      expect(hasher.saltAndHash('1234', salt), isNot(hasher.saltAndHash('4321', salt)));
    });

    test('hash differs for the same pin with different salts', () {
      const hasher = CryptoPasscodeHasher();
      const pin = '1234';
      expect(
        hasher.saltAndHash(pin, hasher.generateSalt()),
        isNot(hasher.saltAndHash(pin, hasher.generateSalt())),
      );
    });

    test('cleartext pin never appears in the salt or hash output', () {
      const hasher = CryptoPasscodeHasher();
      const pin = 'very-secret-pin-2580';
      final salt = hasher.generateSalt();
      final hash = hasher.saltAndHash(pin, salt);
      expect(salt.contains(pin), isFalse, reason: 'salt must not leak the cleartext pin');
      expect(hash.contains(pin), isFalse, reason: 'hash must not leak the cleartext pin');
      expect(hash.length, 64);
    });

    test('hash output is lowercase hex', () {
      const hasher = CryptoPasscodeHasher();
      final hash = hasher.saltAndHash('0000', hasher.generateSalt());
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(hash), isTrue);
    });
  });
}
