import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:test_server/server.dart';

void main() {
  late Handler handler;

  setUp(() {
    handler = buildHandler(enableLogging: false);
  });

  group('POST /v1/auth/issue', () {
    test('issues a session for valid credentials', () async {
      final response = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/v1/auth/issue'),
          body: jsonEncode(<String, Object?>{'email': 'a@b.c', 'password': 'pw'}),
          headers: <String, String>{'content-type': 'application/json'},
        ),
      );
      expect(response.statusCode, 200);
      final body = jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect(body['accessToken'], isA<String>());
      expect(body['refreshToken'], isA<String>());
      expect(body['userId'], isA<String>());
      expect(body['expiresAt'], isA<String>());
    });

    test('yields 401 when the password is missing', () async {
      final response = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/v1/auth/issue'),
          body: jsonEncode(<String, Object?>{'email': 'a@b.c'}),
          headers: <String, String>{'content-type': 'application/json'},
        ),
      );
      expect(response.statusCode, 401);
    });

    test('yields 400 for malformed JSON', () async {
      final response = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/v1/auth/issue'),
          body: 'not json',
          headers: <String, String>{'content-type': 'application/json'},
        ),
      );
      expect(response.statusCode, 400);
    });
  });

  group('POST /v1/auth/refresh', () {
    test('rotates the refresh token and inherits the same user id', () async {
      final issued = await _issue(handler, email: 'a@b.c');
      final refreshResponse = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/v1/auth/refresh'),
          body: jsonEncode(<String, Object?>{'refreshToken': issued['refreshToken']}),
          headers: <String, String>{'content-type': 'application/json'},
        ),
      );
      expect(refreshResponse.statusCode, 200);
      final body = jsonDecode(await refreshResponse.readAsString()) as Map<String, dynamic>;
      expect(body['accessToken'], isA<String>());
      expect(body['refreshToken'], isA<String>());
      expect(body['refreshToken'], isNot(equals(issued['refreshToken'])));
      expect(body['expiresAt'], isA<String>());

      // The rotated token mints the same user id on the next refresh.
      final secondResponse = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/v1/auth/refresh'),
          body: jsonEncode(<String, Object?>{'refreshToken': body['refreshToken']}),
          headers: <String, String>{'content-type': 'application/json'},
        ),
      );
      expect(secondResponse.statusCode, 200);
    });

    test('rejects a replayed (already-rotated) refresh token with 401', () async {
      final issued = await _issue(handler, email: 'a@b.c');
      final firstRefresh = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/v1/auth/refresh'),
          body: jsonEncode(<String, Object?>{'refreshToken': issued['refreshToken']}),
          headers: <String, String>{'content-type': 'application/json'},
        ),
      );
      expect(firstRefresh.statusCode, 200);

      final replay = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/v1/auth/refresh'),
          body: jsonEncode(<String, Object?>{'refreshToken': issued['refreshToken']}),
          headers: <String, String>{'content-type': 'application/json'},
        ),
      );
      expect(replay.statusCode, 401);
    });

    test('yields 401 for an unknown refresh token', () async {
      final response = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/v1/auth/refresh'),
          body: jsonEncode(<String, Object?>{'refreshToken': 'rt-bogus'}),
          headers: <String, String>{'content-type': 'application/json'},
        ),
      );
      expect(response.statusCode, 401);
    });
  });

  group('POST /v1/auth/logout', () {
    test('responds 204 and invalidates the refresh token', () async {
      final issued = await _issue(handler, email: 'a@b.c');

      final logoutResponse = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/v1/auth/logout'),
          body: jsonEncode(<String, Object?>{'refreshToken': issued['refreshToken']}),
          headers: <String, String>{'content-type': 'application/json'},
        ),
      );
      expect(logoutResponse.statusCode, 204);
      expect(await logoutResponse.readAsString(), '');

      // The logged-out token can no longer refresh.
      final refreshResponse = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/v1/auth/refresh'),
          body: jsonEncode(<String, Object?>{'refreshToken': issued['refreshToken']}),
          headers: <String, String>{'content-type': 'application/json'},
        ),
      );
      expect(refreshResponse.statusCode, 401);
    });

    test('is idempotent: 204 even with no body', () async {
      final response = await handler(Request('POST', Uri.parse('http://localhost/v1/auth/logout')));
      expect(response.statusCode, 204);
    });
  });
}

Future<Map<String, dynamic>> _issue(Handler handler, {required String email}) async {
  final response = await handler(
    Request(
      'POST',
      Uri.parse('http://localhost/v1/auth/issue'),
      body: jsonEncode(<String, Object?>{'email': email, 'password': 'pw'}),
      headers: <String, String>{'content-type': 'application/json'},
    ),
  );
  expect(response.statusCode, 200);
  return jsonDecode(await response.readAsString()) as Map<String, dynamic>;
}
