import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:test_server/server.dart';

void main() {
  late Handler handler;

  setUp(() {
    handler = buildHandler(enableLogging: false);
  });

  group('GET /healthz', () {
    test('responds 200', () async {
      final response = await handler(Request('GET', Uri.parse('http://localhost/healthz')));
      expect(response.statusCode, 200);
      expect(await response.readAsString(), 'ok');
    });
  });

  group('POST /v1/crashes', () {
    test('responds 204 for a well-formed report', () async {
      final response = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/v1/crashes'),
          body: jsonEncode(<String, Object?>{
            'message': 'StateError: bad state',
            'stack': '#0 main (file.dart:1)',
            'context': <String, Object?>{'route': '/home'},
            'platform': 'macos',
            'appVersion': '1.0.0',
          }),
          headers: <String, String>{'content-type': 'application/json'},
        ),
      );
      expect(response.statusCode, 204);
      expect(await response.readAsString(), '');
    });

    test('accepts a report without the optional stack field', () async {
      final response = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/v1/crashes'),
          body: jsonEncode(<String, Object?>{
            'message': 'boom',
            'context': <String, Object?>{},
            'platform': 'ios',
            'appVersion': '1.2.3',
          }),
          headers: <String, String>{'content-type': 'application/json'},
        ),
      );
      expect(response.statusCode, 204);
    });

    test('responds 400 for malformed JSON', () async {
      final response = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/v1/crashes'),
          body: 'not json',
          headers: <String, String>{'content-type': 'application/json'},
        ),
      );
      expect(response.statusCode, 400);
    });

    test('responds 400 when the body is not a JSON object', () async {
      final response = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/v1/crashes'),
          body: jsonEncode(<Object?>[1, 2, 3]),
          headers: <String, String>{'content-type': 'application/json'},
        ),
      );
      expect(response.statusCode, 400);
    });
  });

  group('GET /v1/remote-config', () {
    test('returns the canonical payload with revision 1', () async {
      final response = await handler(
        Request(
          'GET',
          Uri.parse('http://localhost/v1/remote-config?deviceId=d1&platform=macos&version=1.0.0'),
        ),
      );
      expect(response.statusCode, 200);
      expect(response.headers['content-type'], contains('application/json'));
      expect(response.headers['etag'], '"1"');

      final body = jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect(body['revision'], '1');
      expect(body['flags'], <String, Object?>{});
      expect(body['experiments'], <String, Object?>{});
      final versionPolicy = body['versionPolicy'] as Map<String, dynamic>;
      expect(
        versionPolicy.keys,
        containsAll(<String>{
          'minVersion',
          'latestVersion',
          'hardBlockBelow',
          'softBlockBelow',
          'storeUrl',
          'message',
        }),
      );
      for (final value in versionPolicy.values) {
        expect(value, isNull);
      }
    });

    test('returns 304 on a matching If-None-Match', () async {
      final response = await handler(
        Request(
          'GET',
          Uri.parse('http://localhost/v1/remote-config'),
          headers: <String, String>{'if-none-match': '"1"'},
        ),
      );
      expect(response.statusCode, 304);
      expect(response.headers['etag'], '"1"');
    });

    test('returns 304 on If-None-Match: *', () async {
      final response = await handler(
        Request(
          'GET',
          Uri.parse('http://localhost/v1/remote-config'),
          headers: <String, String>{'if-none-match': '*'},
        ),
      );
      expect(response.statusCode, 304);
    });

    test('returns 304 on a matching ?rev= query', () async {
      final response = await handler(
        Request('GET', Uri.parse('http://localhost/v1/remote-config?rev=1')),
      );
      expect(response.statusCode, 304);
    });

    test('returns 200 when ?rev= does not match', () async {
      final response = await handler(
        Request('GET', Uri.parse('http://localhost/v1/remote-config?rev=0')),
      );
      expect(response.statusCode, 200);
    });
  });
}
