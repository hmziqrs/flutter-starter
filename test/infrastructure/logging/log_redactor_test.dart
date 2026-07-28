import 'package:flutter_test/flutter_test.dart';
import 'package:starter/infrastructure/logging/log_redactor.dart';

void main() {
  const redactor = LogRedactor();

  test('redacts bearer tokens and sensitive assignments', () {
    final redacted = redactor.redactText(
      'Authorization: Bearer abc.def token=secret-value password=hunter2',
    );

    expect(redacted, isNot(contains('abc.def')));
    expect(redacted, isNot(contains('secret-value')));
    expect(redacted, isNot(contains('hunter2')));
    expect(redacted, contains(LogRedactor.replacement));
  });

  test('redacts sensitive context recursively', () {
    final redacted = redactor.redactContext(
      <String, Object?>{
        'request_id': 'request-1',
        'access_token': 'top-secret',
        'nested': <String, Object?>{
          'password': 'hunter2',
          'message': 'otp=123456',
        },
      },
    );

    expect(redacted['request_id'], 'request-1');
    expect(redacted['access_token'], LogRedactor.replacement);
    expect(
      redacted['nested'],
      <String, Object?>{
        'password': LogRedactor.replacement,
        'message': 'otp=${LogRedactor.replacement}',
      },
    );
  });

  test('redacts email addresses embedded in free text', () {
    final redacted = redactor.redactText(
      'Contact user@example.com or john.doe+filter@sub.example.co for help',
    );

    expect(redacted, isNot(contains('user@example.com')));
    expect(redacted, isNot(contains('john.doe+filter@sub.example.co')));
    expect(redacted, contains(LogRedactor.replacement));
  });

  test('redacts E.164 phone numbers', () {
    final redacted = redactor.redactText('Call +14155551234 now');

    expect(redacted, 'Call ${LogRedactor.replacement} now');
    expect(redacted, isNot(contains('+14155551234')));
  });

  test('redacts Luhn-valid card numbers with separators', () {
    final redacted = redactor.redactText('Card 4111 1111 1111 1111 charged');

    expect(redacted, 'Card ${LogRedactor.replacement} charged');
    expect(redacted, isNot(contains('4111')));
  });

  test('redacts Luhn-valid card numbers without separators', () {
    final redacted = redactor.redactText('Card 4111111111111111 charged');

    expect(redacted, 'Card ${LogRedactor.replacement} charged');
  });

  test('preserves Luhn-invalid digit runs to keep diagnostics readable', () {
    // Same as the Visa test card with the check digit bumped, so it fails Luhn.
    final redacted = redactor.redactText('ref 4111111111111112 done');

    expect(redacted, 'ref 4111111111111112 done');
    expect(redacted, isNot(contains(LogRedactor.replacement)));
  });

  test('redacts standalone JWT bodies', () {
    final redacted = redactor.redactText('jwt eyJabc.def.ghi end');

    expect(redacted, 'jwt ${LogRedactor.replacement} end');
    expect(redacted, isNot(contains('eyJabc')));
  });

  test('collapses Bearer jwt in a single pass before the jwt pass', () {
    final redacted = redactor.redactText(
      'Authorization: Bearer eyJabc.def.ghi',
    );

    expect(redacted, 'Authorization: Bearer ${LogRedactor.replacement}');
    expect(redacted, isNot(contains('eyJ')));
  });

  test('redacts token-bearing query-string parameters', () {
    final redacted = redactor.redactText(
      '/cb?access_token=abc123&refresh_token=def456&state=xyz',
    );

    expect(redacted, contains('?access_token=${LogRedactor.replacement}'));
    expect(redacted, contains('&refresh_token=${LogRedactor.replacement}'));
    expect(redacted, contains('state=xyz'));
    expect(redacted, isNot(contains('abc123')));
    expect(redacted, isNot(contains('def456')));
  });

  test('preserves diagnostic-style identifiers (negative case)', () {
    final redacted = redactor.redactText('STARTUP-CONFIG-12345 failed');

    expect(redacted, 'STARTUP-CONFIG-12345 failed');
    expect(redacted, isNot(contains(LogRedactor.replacement)));
  });

  test('redacts delimited keys but not camelCase compounds', () {
    final redacted = redactor.redactContext(
      <String, Object?>{
        'email': 'user@example.com',
        'emailEnabled': true,
        'card_number': '4111111111111111',
        'cardType': 'visa',
        'request_id': 'req-1',
      },
    );

    expect(redacted['email'], LogRedactor.replacement);
    expect(redacted['emailEnabled'], true);
    expect(redacted['card_number'], LogRedactor.replacement);
    expect(redacted['cardType'], 'visa');
    expect(redacted['request_id'], 'req-1');
  });
}
