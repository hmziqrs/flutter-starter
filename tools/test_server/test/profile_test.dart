import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:test_server/server.dart';

void main() {
  late Handler handler;

  setUp(() {
    handler = buildHandler(enableLogging: false);
  });

  group('GET /v1/profile', () {
    test('requires a Bearer access token (401 when absent)', () async {
      final response = await handler(Request('GET', Uri.parse('http://localhost/v1/profile')));
      expect(response.statusCode, 401);
    });

    test('rejects an unknown access token with 401', () async {
      final response = await handler(
        Request(
          'GET',
          Uri.parse('http://localhost/v1/profile'),
          headers: <String, String>{'authorization': 'Bearer at-bogus'},
        ),
      );
      expect(response.statusCode, 401);
    });

    test('rejects a malformed Authorization header with 401', () async {
      final response = await handler(
        Request(
          'GET',
          Uri.parse('http://localhost/v1/profile'),
          headers: <String, String>{'authorization': 'notabearer'},
        ),
      );
      expect(response.statusCode, 401);
    });

    test('returns the profile shape for a registered + verified user', () async {
      final accessToken = await _registerAndVerify(
        handler,
        email: 'profile-get@example.com',
        displayName: 'Prof Get',
      );
      final response = await handler(
        Request(
          'GET',
          Uri.parse('http://localhost/v1/profile'),
          headers: <String, String>{'authorization': 'Bearer $accessToken'},
        ),
      );
      expect(response.statusCode, 200);
      final body = jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect(body, containsPair('displayName', 'Prof Get'));
      // username is the email local-part.
      expect(body, containsPair('username', 'profile-get'));
      expect(body, containsPair('email', 'profile-get@example.com'));
      // bio starts empty.
      expect(body, containsPair('bio', ''));
    });
  });

  group('PUT /v1/profile', () {
    test('requires auth (401 without a token)', () async {
      final response = await handler(
        Request(
          'PUT',
          Uri.parse('http://localhost/v1/profile'),
          body: jsonEncode(<String, Object>{'displayName': 'X'}),
          headers: <String, String>{'content-type': 'application/json'},
        ),
      );
      expect(response.statusCode, 401);
    });

    test('updates displayName and bio, and ignores email', () async {
      final accessToken = await _registerAndVerify(
        handler,
        email: 'profile-put@example.com',
        displayName: 'Original',
      );
      final response = await handler(
        Request(
          'PUT',
          Uri.parse('http://localhost/v1/profile'),
          body: jsonEncode(<String, Object>{
            'displayName': 'Updated',
            'bio': 'hello world',
            // email is read-only — must be ignored even if sent.
            'email': 'should-be-ignored@example.com',
          }),
          headers: <String, String>{
            'content-type': 'application/json',
            'authorization': 'Bearer $accessToken',
          },
        ),
      );
      expect(response.statusCode, 200);
      final body = jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect(body, containsPair('displayName', 'Updated'));
      expect(body, containsPair('bio', 'hello world'));
      // email preserved, username derived from the original local-part.
      expect(body, containsPair('email', 'profile-put@example.com'));
      expect(body, containsPair('username', 'profile-put'));

      // The mutation persists on a subsequent GET.
      final getResponse = await handler(
        Request(
          'GET',
          Uri.parse('http://localhost/v1/profile'),
          headers: <String, String>{'authorization': 'Bearer $accessToken'},
        ),
      );
      final getBody = jsonDecode(await getResponse.readAsString()) as Map<String, dynamic>;
      expect(getBody, containsPair('displayName', 'Updated'));
      expect(getBody, containsPair('bio', 'hello world'));
    });

    test('can clear bio to an empty string', () async {
      final accessToken = await _registerAndVerify(
        handler,
        email: 'profile-clear@example.com',
        displayName: 'Clear',
      );
      // Set a bio first.
      await handler(
        Request(
          'PUT',
          Uri.parse('http://localhost/v1/profile'),
          body: jsonEncode(<String, Object>{'bio': 'then-empty'}),
          headers: <String, String>{
            'content-type': 'application/json',
            'authorization': 'Bearer $accessToken',
          },
        ),
      );
      // Now clear it — an empty string is a value, not "omit".
      final response = await handler(
        Request(
          'PUT',
          Uri.parse('http://localhost/v1/profile'),
          body: jsonEncode(<String, Object>{'bio': ''}),
          headers: <String, String>{
            'content-type': 'application/json',
            'authorization': 'Bearer $accessToken',
          },
        ),
      );
      expect(response.statusCode, 200);
      final body = jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect(body, containsPair('bio', ''));
    });
  });
}

/// Drives the register -> OTP verify flow and returns the access token the
/// verified session mints, so a profile test can act as an authenticated user.
Future<String> _registerAndVerify(
  Handler handler, {
  required String email,
  required String displayName,
}) async {
  final regResponse = await handler(
    Request(
      'POST',
      Uri.parse('http://localhost/v1/auth/register'),
      body: jsonEncode(<String, Object>{
        'email': email,
        'password': 'pw',
        'displayName': displayName,
      }),
      headers: <String, String>{'content-type': 'application/json', 'X-Api-Key': 'dev'},
    ),
  );
  expect(regResponse.statusCode, 200);
  final regBody = jsonDecode(await regResponse.readAsString()) as Map<String, dynamic>;

  final verifyResponse = await handler(
    Request(
      'POST',
      Uri.parse('http://localhost/v1/otp/verify'),
      body: jsonEncode(<String, Object>{
        'attempt_token': regBody['attempt_token'] as String,
        'code': '123456',
      }),
      headers: <String, String>{'content-type': 'application/json'},
    ),
  );
  expect(verifyResponse.statusCode, 200);
  final body = jsonDecode(await verifyResponse.readAsString()) as Map<String, dynamic>;
  return body['access_token'] as String;
}
