import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

const Map<String, String> _jsonHeaders = <String, String>{
  'content-type': 'application/json; charset=utf-8',
};

/// Hard cap on the screenshot payload (base64 length). 2 MiB of base64 is well
/// beyond a reasonable screenshot and protects the in-memory store from a
/// runaway upload; a larger payload returns 413.
const int _maxScreenshotBase64Length = 2 * 1024 * 1024;

/// Triage state of an accepted submission. Mirrors the client contract: a
/// freshly accepted report starts `queued` and moves to `triaged` once a human
/// reviews it (the status endpoint reports the current value).
const String _initialTriageState = 'queued';

/// In-memory table of accepted feedback submissions: `id -> _FeedbackRecord`.
/// The status endpoint reads this table; an unknown id returns 404. Single-
/// process test server only — no persistence across restarts.
final Map<String, _FeedbackRecord> _submissions = <String, _FeedbackRecord>{};

/// Monotonic counter combined with a microsecond timestamp so feedback ids
/// never collide within a single server process (mirrors otp._issueToken).
int _counter = 0;

String _issueId() {
  _counter += 1;
  return 'fb-${DateTime.now().toUtc().microsecondsSinceEpoch}-$_counter';
}

DateTime _now() => DateTime.now().toUtc();

/// Mounts the feedback contract onto [router]:
/// - `POST /v1/feedback`              `{message, email?, screenshotMime?,
///   screenshotBase64?, appMetadata?}` -> `201 {id}` on accept, `422` on
///   invalid (empty message / malformed email / unknown mime), `413` when the
///   screenshot exceeds the cap.
/// - `GET  /v1/feedback/{id}/status`  -> `200 {state}` for a known id, `404`
///   for an unknown id.
///
/// No PII logging: the body carries the user message + email verbatim and is
/// never echoed to the server log. The record keeps only what the triage state
/// needs (id + state + accepted-at).
void registerRoutes(Router router) {
  router.post('/v1/feedback', _submit);
  router.get('/v1/feedback/<id>/status', _status);
}

Future<Response> _submit(Request request) async {
  final decoded = await _decode(request);
  if (decoded == null) {
    return _invalid();
  }
  final message = decoded['message'];
  if (message is! String || message.trim().isEmpty) {
    return _invalid();
  }
  final email = decoded['email'];
  if (email != null && (email is! String || !_looksLikeEmail(email))) {
    return _invalid();
  }
  final screenshotMime = decoded['screenshotMime'];
  final screenshotBase64 = decoded['screenshotBase64'];
  if (screenshotMime != null || screenshotBase64 != null) {
    if (screenshotMime is! String ||
        !_isKnownImageMime(screenshotMime) ||
        screenshotBase64 is! String ||
        screenshotBase64.isEmpty) {
      return _invalid();
    }
    if (screenshotBase64.length > _maxScreenshotBase64Length) {
      return Response(
        413,
        body: jsonEncode(<String, String>{'error': 'screenshot too large'}),
        headers: _jsonHeaders,
      );
    }
  }
  // appMetadata is optional and not validated beyond shape — it is read-only
  // environment context the client already built (version / platform / locale).
  final id = _issueId();
  _submissions[id] = _FeedbackRecord(id: id, state: _initialTriageState, acceptedAt: _now());
  return Response.ok(jsonEncode(<String, Object>{'id': id}), headers: _jsonHeaders);
}

Future<Response> _status(Request request, String id) async {
  final record = _submissions[id];
  if (record == null) {
    return Response(
      404,
      body: jsonEncode(<String, String>{'error': 'unknown id'}),
      headers: _jsonHeaders,
    );
  }
  return Response.ok(jsonEncode(<String, Object>{'state': record.state}), headers: _jsonHeaders);
}

bool _looksLikeEmail(String value) {
  // Minimal shape check: must contain exactly one '@' with non-empty local +
  // domain parts. The real validation lives in the client; the server is a
  // backstop so a malformed payload never enters the triage queue.
  final at = value.indexOf('@');
  if (at <= 0) return false;
  final dot = value.lastIndexOf('.');
  return dot > at + 1 && dot < value.length - 1;
}

bool _isKnownImageMime(String mime) {
  return switch (mime) {
    'image/png' || 'image/jpeg' || 'image/webp' => true,
    _ => false,
  };
}

Response _invalid() => Response(
  422,
  body: jsonEncode(<String, String>{'error': 'invalid feedback submission'}),
  headers: _jsonHeaders,
);

Future<Map<String, dynamic>?> _decode(Request request) async {
  try {
    final body = await request.readAsString();
    if (body.isEmpty) {
      return const <String, dynamic>{};
    }
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    return decoded;
  } on FormatException {
    return null;
  }
}

final class _FeedbackRecord {
  const _FeedbackRecord({required this.id, required this.state, required this.acceptedAt});

  final String id;
  final String state;
  final DateTime acceptedAt;
}
