import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:test_server/server.dart';

void main() {
  late Handler handler;

  setUp(() {
    handler = buildHandler(enableLogging: false);
  });

  group('POST /v1/events', () {
    test('responds 204 for a well-formed event batch', () async {
      final response = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/v1/events'),
          body: jsonEncode(<String, Object?>{
            'events': <Map<String, Object?>>[
              <String, Object?>{
                'type': 'screen_view',
                'name': 'home',
                'props': <String, Object?>{'layout': 'compact'},
                'ts': '2026-07-27T00:00:00.000Z',
              },
              <String, Object?>{
                'type': 'tap',
                'name': 'open-profile',
                'ts': '2026-07-27T00:00:01.000Z',
              },
            ],
            'userId': 'demo-user',
          }),
          headers: <String, String>{'content-type': 'application/json'},
        ),
      );
      expect(response.statusCode, 204);
      expect(await response.readAsString(), '');
    });

    test('responds 204 for a batch with an empty events list', () async {
      final response = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/v1/events'),
          body: jsonEncode(<String, Object?>{'events': <Object>[]}),
          headers: <String, String>{'content-type': 'application/json'},
        ),
      );
      expect(response.statusCode, 204);
    });

    test('responds 204 without the optional userId field', () async {
      final response = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/v1/events'),
          body: jsonEncode(<String, Object?>{
            'events': <Map<String, Object?>>[
              <String, Object?>{
                'type': 'funnel_step',
                'name': 'onboarding_continue',
                'ts': '2026-07-27T00:00:00.000Z',
              },
            ],
          }),
          headers: <String, String>{'content-type': 'application/json'},
        ),
      );
      expect(response.statusCode, 204);
    });

    test('responds 400 when the body is not a JSON object', () async {
      final response = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/v1/events'),
          body: jsonEncode(<Object>[1, 2, 3]),
          headers: <String, String>{'content-type': 'application/json'},
        ),
      );
      expect(response.statusCode, 400);
    });

    test('responds 400 when the events field is missing', () async {
      final response = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/v1/events'),
          body: jsonEncode(<String, Object?>{'userId': 'demo-user'}),
          headers: <String, String>{'content-type': 'application/json'},
        ),
      );
      expect(response.statusCode, 400);
    });

    test('responds 400 when an event entry is not an object', () async {
      final response = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/v1/events'),
          body: jsonEncode(<String, Object?>{
            'events': <Object?>['not-an-object'],
          }),
          headers: <String, String>{'content-type': 'application/json'},
        ),
      );
      expect(response.statusCode, 400);
    });

    test('responds 400 for malformed JSON', () async {
      final response = await handler(
        Request(
          'POST',
          Uri.parse('http://localhost/v1/events'),
          body: 'not json',
          headers: <String, String>{'content-type': 'application/json'},
        ),
      );
      expect(response.statusCode, 400);
    });
  });
}
