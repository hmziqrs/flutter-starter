import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:test_server/server.dart';

void main() {
  late Handler handler;

  setUp(() {
    handler = buildHandler(enableLogging: false);
  });

  group('POST /v1/otp/issue', () {
    test('responds 200 with attempt_token + expires_at + channel', () async {
      final response = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/v1/otp/issue'),
          body: jsonEncode(<String, Object>{'purpose': 'mfa', 'identifier': 'user@example.com'}),
          headers: <String, String>{'content-type': 'application/json'},
        ),
      );
      expect(response.statusCode, 200);
      final body = jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect(body, containsPair('attempt_token', isA<String>()));
      expect(body, containsPair('expires_at', isA<String>()));
      expect(body, containsPair('channel', 'sms'));
      // dev_code is only returned with the dev API key header (not set here).
      expect(body, isNot(contains('dev_code')));
    });

    test('returns dev_code only when the dev API key header is present', () async {
      final response = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/v1/otp/issue'),
          body: jsonEncode(<String, Object>{'purpose': 'mfa', 'identifier': 'user@example.com'}),
          headers: <String, String>{'content-type': 'application/json', 'X-Api-Key': 'dev'},
        ),
      );
      expect(response.statusCode, 200);
      final body = jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect(body, containsPair('dev_code', isA<String>()));
      // The dev_code is a 6-digit string.
      expect((body['dev_code'] as String).length, 6);
    });

    test('responds 400 for an unknown purpose', () async {
      final response = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/v1/otp/issue'),
          body: jsonEncode(<String, Object>{
            'purpose': 'unknown-purpose',
            'identifier': 'user@example.com',
          }),
          headers: <String, String>{'content-type': 'application/json'},
        ),
      );
      expect(response.statusCode, 400);
    });
  });

  group('POST /v1/otp/verify', () {
    test('valid code returns 200 {valid: true} and consumes the attempt token', () async {
      final issueResponse = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/v1/otp/issue'),
          body: jsonEncode(<String, Object>{'purpose': 'mfa', 'identifier': 'user@example.com'}),
          headers: <String, String>{'content-type': 'application/json', 'X-Api-Key': 'dev'},
        ),
      );
      final issued = jsonDecode(await issueResponse.readAsString()) as Map<String, dynamic>;
      final attemptToken = issued['attempt_token'] as String;
      final code = issued['dev_code'] as String;

      final verifyResponse = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/v1/otp/verify'),
          body: jsonEncode(<String, Object>{'attempt_token': attemptToken, 'code': code}),
          headers: <String, String>{'content-type': 'application/json'},
        ),
      );
      expect(verifyResponse.statusCode, 200);
      final body = jsonDecode(await verifyResponse.readAsString()) as Map<String, dynamic>;
      expect(body, containsPair('valid', true));

      // Replay consumes -> 409 expired.
      final replay = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/v1/otp/verify'),
          body: jsonEncode(<String, Object>{'attempt_token': attemptToken, 'code': code}),
          headers: <String, String>{'content-type': 'application/json'},
        ),
      );
      expect(replay.statusCode, 409);
    });

    test('invalid code returns 200 {valid: false}; 3rd failure locks (429)', () async {
      // Issue fresh.
      final issueResponse = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/v1/otp/issue'),
          body: jsonEncode(<String, Object>{'purpose': 'mfa', 'identifier': 'locker@example.com'}),
          headers: <String, String>{'content-type': 'application/json', 'X-Api-Key': 'dev'},
        ),
      );
      final issued = jsonDecode(await issueResponse.readAsString()) as Map<String, dynamic>;
      final attemptToken = issued['attempt_token'] as String;

      // Two free failures (freeAttemptsBeforeLockout == 2).
      for (var i = 0; i < 2; i++) {
        final r = await handler(
          Request(
            'POST',
            Uri.parse('http://localhost/v1/otp/verify'),
            body: jsonEncode(<String, Object>{'attempt_token': attemptToken, 'code': '000000'}),
            headers: <String, String>{'content-type': 'application/json'},
          ),
        );
        expect(r.statusCode, 200);
        final body = jsonDecode(await r.readAsString()) as Map<String, dynamic>;
        expect(body, containsPair('valid', false));
      }

      // Third failure locks for 30 seconds (agrees with the client schedule).
      final locked = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/v1/otp/verify'),
          body: jsonEncode(<String, Object>{'attempt_token': attemptToken, 'code': '000000'}),
          headers: <String, String>{'content-type': 'application/json'},
        ),
      );
      expect(locked.statusCode, 429);
      final body = jsonDecode(await locked.readAsString()) as Map<String, dynamic>;
      expect(body, containsPair('error', 'locked'));
      expect(body, containsPair('retry_after_seconds', isA<int>()));
      expect(body['retry_after_seconds'] as int, lessThanOrEqualTo(30));
    });
  });

  group('POST /v1/otp/resend', () {
    test('responds 200 with a fresh attempt_token + refreshed expiry', () async {
      final response = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/v1/otp/resend'),
          body: jsonEncode(<String, Object>{'identifier': 'user@example.com', 'purpose': 'mfa'}),
          headers: <String, String>{'content-type': 'application/json'},
        ),
      );
      expect(response.statusCode, 200);
      final body = jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect(body, containsPair('attempt_token', isA<String>()));
      expect(body, containsPair('expires_at', isA<String>()));
    });
  });
}
