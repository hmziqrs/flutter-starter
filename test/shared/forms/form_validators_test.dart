import 'package:flutter_test/flutter_test.dart';
import 'package:starter/shared/forms/form_validators.dart';

void main() {
  group('validateRequired', () {
    test('rejects null with the supplied message', () {
      expect(validateRequired(null, 'required'), 'required');
    });

    test('rejects an empty string with the supplied message', () {
      expect(validateRequired('', 'required'), 'required');
    });

    test('accepts a non-empty value and returns null', () {
      expect(validateRequired('value', 'required'), isNull);
    });

    test('treats a whitespace-only value as present (no normalization)', () {
      expect(validateRequired(' ', 'required'), isNull);
    });
  });

  group('validateEmail', () {
    const required = 'email-required';
    const invalid = 'email-invalid';

    test('rejects null with the required message', () {
      expect(
        validateEmail(null, requiredMessage: required, invalidMessage: invalid),
        required,
      );
    });

    test('rejects an empty string with the required message', () {
      expect(
        validateEmail('', requiredMessage: required, invalidMessage: invalid),
        required,
      );
    });

    test('rejects a value with no @ with the invalid message', () {
      expect(
        validateEmail('no-at-sign', requiredMessage: required, invalidMessage: invalid),
        invalid,
      );
    });

    test('rejects a value whose @ is at the start', () {
      expect(
        validateEmail('@example.com', requiredMessage: required, invalidMessage: invalid),
        invalid,
      );
    });

    test('rejects a value with no dot in the domain tail', () {
      expect(
        validateEmail('a@b', requiredMessage: required, invalidMessage: invalid),
        invalid,
      );
    });

    test('rejects a value whose dot is immediately after the @', () {
      expect(
        validateEmail('a@.com', requiredMessage: required, invalidMessage: invalid),
        invalid,
      );
    });

    test('rejects a value whose dot is the final character', () {
      expect(
        validateEmail('a@b.', requiredMessage: required, invalidMessage: invalid),
        invalid,
      );
    });

    test('accepts a well-formed email', () {
      expect(
        validateEmail('a@b.c', requiredMessage: required, invalidMessage: invalid),
        isNull,
      );
    });

    test('trims surrounding whitespace before checking the shape', () {
      expect(
        validateEmail('  a@b.c  ', requiredMessage: required, invalidMessage: invalid),
        isNull,
      );
    });
  });

  group('validatePassword', () {
    const required = 'password-required';
    const weak = 'password-weak';

    test('rejects null with the required message', () {
      expect(
        validatePassword(null, requiredMessage: required, weakMessage: weak),
        required,
      );
    });

    test('rejects an empty string with the required message', () {
      expect(
        validatePassword('', requiredMessage: required, weakMessage: weak),
        required,
      );
    });

    test('rejects a value shorter than 8 characters with the weak message', () {
      expect(
        validatePassword('Short1', requiredMessage: required, weakMessage: weak),
        weak,
      );
    });

    test('rejects a value with no uppercase letter', () {
      expect(
        validatePassword('alllowercase1', requiredMessage: required, weakMessage: weak),
        weak,
      );
    });

    test('rejects a value with no digit', () {
      expect(
        validatePassword('NoDigitHere', requiredMessage: required, weakMessage: weak),
        weak,
      );
    });

    test('accepts a value that meets length, uppercase, and digit rules', () {
      expect(
        validatePassword('Valid1Ab', requiredMessage: required, weakMessage: weak),
        isNull,
      );
    });

    test('does not trim the secret: a space-preserved value is still accepted', () {
      expect(
        validatePassword(' Abcdefg1 ', requiredMessage: required, weakMessage: weak),
        isNull,
      );
    });
  });
}
