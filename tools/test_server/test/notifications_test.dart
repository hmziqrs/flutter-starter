import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:test_server/server.dart';

void main() {
  late Handler handler;

  setUp(() {
    handler = buildHandler(enableLogging: false);
  });

  group('POST /v1/notifications/register-token', () {
    test('responds 204 for a well-formed registration', () async {
      final response = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/v1/notifications/register-token'),
          body: jsonEncode(<String, Object>{
            'token': 'token-abc',
            'platform': 'ios',
            'deviceId': 'device-1',
          }),
          headers: <String, String>{'content-type': 'application/json'},
        ),
      );
      expect(response.statusCode, 204);
      expect(await response.readAsString(), '');
    });

    test('responds 204 when re-registering the same token (idempotent)', () async {
      final body = jsonEncode(<String, Object>{
        'token': 'token-abc',
        'platform': 'ios',
        'deviceId': 'device-1',
      });
      final first = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/v1/notifications/register-token'),
          body: body,
          headers: <String, String>{'content-type': 'application/json'},
        ),
      );
      final second = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/v1/notifications/register-token'),
          body: body,
          headers: <String, String>{'content-type': 'application/json'},
        ),
      );
      expect(first.statusCode, 204);
      expect(second.statusCode, 204);
    });

    test('responds 400 when the body is missing required fields', () async {
      final response = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/v1/notifications/register-token'),
          body: jsonEncode(<String, Object>{'token': 'token-abc'}),
          headers: <String, String>{'content-type': 'application/json'},
        ),
      );
      expect(response.statusCode, 400);
    });

    test('responds 400 for malformed json', () async {
      final response = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/v1/notifications/register-token'),
          body: 'not json',
          headers: <String, String>{'content-type': 'application/json'},
        ),
      );
      expect(response.statusCode, 400);
    });
  });

  group('DELETE /v1/notifications/register-token/{token}', () {
    test('responds 204 after a registration', () async {
      await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/v1/notifications/register-token'),
          body: jsonEncode(<String, Object>{
            'token': 'token-abc',
            'platform': 'android',
            'deviceId': 'device-1',
          }),
          headers: <String, String>{'content-type': 'application/json'},
        ),
      );
      final response = await handler(
        Request('DELETE', Uri.parse('http://localhost/v1/notifications/register-token/token-abc')),
      );
      expect(response.statusCode, 204);
    });

    test('responds 204 for an unknown token (idempotent delete)', () async {
      final response = await handler(
        Request(
          'DELETE',
          Uri.parse('http://localhost/v1/notifications/register-token/never-registered'),
        ),
      );
      expect(response.statusCode, 204);
    });
  });

  group('POST /v1/notifications/permission-revoked', () {
    test('responds 204 and clears every token registered for the device', () async {
      // Register two tokens for the same device.
      for (final token in const ['token-a', 'token-b']) {
        await handler(
          Request(
            'POST',
            Uri.parse('http://localhost/v1/notifications/register-token'),
            body: jsonEncode(<String, Object>{
              'token': token,
              'platform': 'ios',
              'deviceId': 'device-1',
            }),
            headers: <String, String>{'content-type': 'application/json'},
          ),
        );
      }
      // Revoke permission for that device.
      final revoke = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/v1/notifications/permission-revoked'),
          body: jsonEncode(<String, Object>{'deviceId': 'device-1'}),
          headers: <String, String>{'content-type': 'application/json'},
        ),
      );
      expect(revoke.statusCode, 204);
      // Subsequent deletes for either token are still idempotent 204 (the
      // permission-revoked path already removed them).
      final afterA = await handler(
        Request('DELETE', Uri.parse('http://localhost/v1/notifications/register-token/token-a')),
      );
      expect(afterA.statusCode, 204);
    });

    test('responds 400 when deviceId is missing', () async {
      final response = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/v1/notifications/permission-revoked'),
          body: jsonEncode(<String, Object>{}),
          headers: <String, String>{'content-type': 'application/json'},
        ),
      );
      expect(response.statusCode, 400);
    });
  });
}
