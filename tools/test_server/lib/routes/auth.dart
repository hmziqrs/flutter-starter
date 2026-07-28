import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

const Map<String, String> _jsonHeaders = <String, String>{
  'content-type': 'application/json; charset=utf-8',
};

/// Lifetime of an issued access token, mirrored from a typical backend policy.
/// Long enough to exercise foreground-refresh tests, short enough to make the
/// "expired while backgrounded" path deterministic.
const Duration _accessTtl = Duration(hours: 1);

/// Monotonic counter combined with a microsecond timestamp so refresh tokens
/// never collide within a single server process (the in-memory token table
/// keys on the literal string).
int _counter = 0;

String _issueToken(String prefix) {
  _counter += 1;
  return '$prefix-${DateTime.now().toUtc().microsecondsSinceEpoch}-$_counter';
}

/// In-memory table of valid refresh tokens: token -> user id.
///
/// Rotated on `/v1/auth/refresh`: the presented token is removed and a fresh
/// one is issued against the same user id, so presenting the old token a
/// second time yields `401` (the issue -> refresh -> logout contract relies on
/// this — returning only an access token on refresh would lose the rotated
/// refresh and strand the client).
final Map<String, String> _refreshTokens = <String, String>{};

/// Derives a stable user id from the submitted email so `/refresh` inherits
/// the same identity from the rotated token (the contract: `userId` seeds
/// `AuthSession.userId`, and `/refresh` does not re-send it).
String _userIdFor(String email) {
  return 'user-${email.hashCode.toRadixString(36)}';
}

DateTime _now() => DateTime.now().toUtc();

/// Mounts the session auth contract (C9) onto [router]:
/// - `POST /v1/auth/issue`   `{email, password}` -> `{accessToken, refreshToken, expiresAt, userId}` or `401`.
/// - `POST /v1/auth/refresh` `{refreshToken}`    -> `{accessToken, refreshToken, expiresAt}` (rotated) or `401`.
/// - `POST /v1/auth/logout`  `{refreshToken?}`   -> `204`.
void registerRoutes(Router router) {
  router.post('/v1/auth/issue', _issue);
  router.post('/v1/auth/refresh', _refresh);
  router.post('/v1/auth/logout', _logout);
}

Future<Response> _issue(Request request) async {
  final decoded = await _decode(request);
  if (decoded == null) {
    return _invalid();
  }
  final email = decoded['email'];
  final password = decoded['password'];
  if (email is! String || email.isEmpty || password is! String || password.isEmpty) {
    return _unauthorized();
  }
  final userId = _userIdFor(email);
  final refreshToken = _issueToken('rt');
  _refreshTokens[refreshToken] = userId;
  return Response.ok(
    jsonEncode(<String, Object>{
      'accessToken': _issueToken('at'),
      'refreshToken': refreshToken,
      'expiresAt': _now().add(_accessTtl).toIso8601String(),
      'userId': userId,
    }),
    headers: _jsonHeaders,
  );
}

Future<Response> _refresh(Request request) async {
  final decoded = await _decode(request);
  if (decoded == null) {
    return _invalid();
  }
  final presented = decoded['refreshToken'];
  if (presented is! String) {
    return _unauthorized();
  }
  // ROTATE: remove the presented token first so a replay yields 401.
  final userId = _refreshTokens.remove(presented);
  if (userId == null) {
    return _unauthorized();
  }
  final rotated = _issueToken('rt');
  _refreshTokens[rotated] = userId;
  return Response.ok(
    jsonEncode(<String, Object>{
      'accessToken': _issueToken('at'),
      'refreshToken': rotated,
      'expiresAt': _now().add(_accessTtl).toIso8601String(),
    }),
    headers: _jsonHeaders,
  );
}

Future<Response> _logout(Request request) async {
  final decoded = await _decode(request);
  // Logout is idempotent: a missing or malformed body still yields 204.
  if (decoded != null) {
    final presented = decoded['refreshToken'];
    if (presented is String) {
      _refreshTokens.remove(presented);
    }
  }
  return Response(204);
}

Future<Map<String, dynamic>?> _decode(Request request) async {
  try {
    final decoded = jsonDecode(await request.readAsString());
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

Response _unauthorized() => Response(
  401,
  body: jsonEncode(<String, String>{'error': 'unauthorized'}),
  headers: _jsonHeaders,
);
