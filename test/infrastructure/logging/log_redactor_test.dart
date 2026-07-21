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
}
