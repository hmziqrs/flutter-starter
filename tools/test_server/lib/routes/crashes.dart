import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

const Map<String, String> _jsonHeaders = <String, String>{
  'content-type': 'application/json; charset=utf-8',
};

/// Maximum number of crash reports retained in the in-memory ring buffer.
const int _ringLimit = 50;

/// In-memory ring buffer holding the most recent crash reports received by the
/// server. Capped at [_ringLimit]; oldest entries are dropped first. The ring
/// is intentionally not exposed over HTTP — it exists for completeness and for
/// ad-hoc inspection during local dev runs.
final List<Map<String, dynamic>> _ring = <Map<String, dynamic>>[];

/// Mounts the crash-reporting contract (C9) onto [router]:
/// `POST /v1/crashes` `{message, stack?, context, platform, appVersion}` -> 204.
void registerRoutes(Router router) {
  router.post('/v1/crashes', _handle);
}

Future<Response> _handle(Request request) async {
  try {
    final decoded = jsonDecode(await request.readAsString());
    if (decoded is! Map<String, dynamic>) {
      return _invalid();
    }
    _store(decoded);
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
