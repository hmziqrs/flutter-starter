import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

const Map<String, String> _jsonHeaders = <String, String>{
  'content-type': 'application/json; charset=utf-8',
};

/// Registered tokens keyed by `token` string. The value carries the
/// `(platform, deviceId)` the client posted so a permission-revoked report can
/// later fan out to every token registered for that device. Stored verbatim —
/// this is a local test fixture, never a production secret store.
final Map<String, _RegisteredToken> _tokens = <String, _RegisteredToken>{};

/// Index of `deviceId -> registered tokens` so a permission-revoked report
/// removes every token registered for that device in one round-trip.
final Map<String, Set<String>> _deviceTokens = <String, Set<String>>{};

final class _RegisteredToken {
  const _RegisteredToken({required this.token, required this.platform, required this.deviceId});

  final String token;
  final String platform;
  final String deviceId;
}

/// Mounts the notifications token-registration / permission contract (C9)
/// onto [router]:
/// - `POST   /v1/notifications/register-token`           `{token, platform, deviceId}` -> 204.
/// - `DELETE /v1/notifications/register-token/{token}`   -> 204.
/// - `POST   /v1/notifications/permission-revoked`       `{deviceId}`                  -> 204.
///
/// Message delivery (FCM / APNs) cannot be mocked by a plain HTTP server
/// (C3 known limitation); the foreground rendering path is covered by
/// `flutter_local_notifications` + a fake messaging repository in the app's
/// unit/widget tests, not by this server.
void registerRoutes(Router router) {
  router.post('/v1/notifications/register-token', _register);
  router.delete('/v1/notifications/register-token/<token>', _unregister);
  router.post('/v1/notifications/permission-revoked', _revoke);
}

Future<Response> _register(Request request) async {
  final decoded = await _decode(request);
  if (decoded == null) {
    return _invalid();
  }
  final token = decoded['token'];
  final platform = decoded['platform'];
  final deviceId = decoded['deviceId'];
  if (token is! String ||
      token.isEmpty ||
      platform is! String ||
      platform.isEmpty ||
      deviceId is! String ||
      deviceId.isEmpty) {
    return _invalid();
  }
  // Idempotent store: re-registering the same token overwrites the previous
  // record (no duplicate keys, no error). The device index is kept in sync.
  _tokens[token] = _RegisteredToken(token: token, platform: platform, deviceId: deviceId);
  _deviceTokens.putIfAbsent(deviceId, () => <String>{}).add(token);
  return Response(204);
}

Response _unregister(Request request) {
  final token = request.params['token'];
  if (token == null || token.isEmpty) {
    return _invalid();
  }
  final removed = _tokens.remove(token);
  if (removed != null) {
    _deviceTokens[removed.deviceId]?.remove(token);
  }
  // Idempotent: deleting an unknown token still yields 204 (the contract is
  // "no token at this address").
  return Response(204);
}

Future<Response> _revoke(Request request) async {
  final decoded = await _decode(request);
  if (decoded == null) {
    return _invalid();
  }
  final deviceId = decoded['deviceId'];
  if (deviceId is! String || deviceId.isEmpty) {
    return _invalid();
  }
  // Drop every token registered for this device — a revoked permission means
  // future pushes would be silently dropped by the OS, so the server stops
  // attempting delivery.
  final tokens = _deviceTokens.remove(deviceId) ?? const <String>{};
  for (final token in tokens) {
    _tokens.remove(token);
  }
  return Response(204);
}

Future<Map<String, dynamic>?> _decode(Request request) async {
  try {
    // `DELETE` has no body; route it through the JSON path anyway with a
    // tolerant fallback so the parser does not throw on an empty stream.
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

Response _invalid() => Response(
  400,
  body: jsonEncode(<String, String>{'error': 'invalid json'}),
  headers: _jsonHeaders,
);
