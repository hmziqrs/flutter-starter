import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

const Map<String, String> _jsonHeaders = <String, String>{
  'content-type': 'application/json; charset=utf-8',
};

/// Maximum number of event batches retained in the in-memory ring buffer.
const int _ringLimit = 100;

/// In-memory ring buffer holding the most recent event batches received by the
/// server. Capped at [_ringLimit]; oldest entries are dropped first. The ring
/// is intentionally not exposed over HTTP — it exists for completeness and for
/// ad-hoc inspection during local dev runs / integration assertions.
final List<Map<String, dynamic>> _ring = <Map<String, dynamic>>[];

/// Mounts the analytics contract (C9) onto [router]:
/// `POST /v1/events` `{ "events": [ { "type": "screen_view"|"tap"|"funnel_step",
/// "name": string, "props": object, "ts": iso8601 } ], "userId": string? }`
/// -> 204.
///
/// Accepts a batch and stores each entry verbatim. Returns `204` on success,
/// `400` for malformed JSON or a body that is not a JSON object / lacks the
/// `events` list. Mirrors the `crashes` route module shape.
void registerRoutes(Router router) {
  router.post('/v1/events', _handle);
}

Future<Response> _handle(Request request) async {
  try {
    final decoded = jsonDecode(await request.readAsString());
    if (decoded is! Map<String, dynamic>) {
      return _invalid();
    }
    final events = decoded['events'];
    if (events is! List<dynamic>) {
      return _invalid();
    }
    for (final entry in events) {
      if (entry is! Map<String, dynamic>) {
        return _invalid();
      }
      _store(entry);
    }
    return Response(204);
  } on FormatException {
    return _invalid();
  }
}

void _store(Map<String, dynamic> entry) {
  _ring.add(<String, dynamic>{...entry, 'receivedAt': DateTime.now().toUtc().toIso8601String()});
  if (_ring.length > _ringLimit) {
    _ring.removeRange(0, _ring.length - _ringLimit);
  }
}

Response _invalid() => Response(
  400,
  body: jsonEncode(<String, String>{'error': 'invalid json'}),
  headers: _jsonHeaders,
);
