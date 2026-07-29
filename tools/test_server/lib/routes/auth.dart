import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../accounts.dart';
import 'otp.dart' as otp;

const Map<String, String> _jsonHeaders = <String, String>{
  'content-type': 'application/json; charset=utf-8',
};

DateTime _now() => DateTime.now().toUtc();

bool _isDevRequest(Request request) => request.headers['x-api-key'] == 'dev';

/// Mounts the session auth contract (C9) onto [router]:
/// - `POST /v1/auth/issue`    `{email, password}` -> `{accessToken, refreshToken, expiresAt, userId}` or `401`.
/// - `POST /v1/auth/register` `{email, password, displayName}` -> registration OTP envelope
///   (`{attempt_token, expires_at, channel, dev_code?}`) or `409 {error:'conflict'}`.
/// - `POST /v1/auth/refresh`  `{refreshToken}` -> `{accessToken, refreshToken, expiresAt}` (rotated) or `401`.
/// - `POST /v1/auth/logout`   `{refreshToken?}` -> `204`.
///
/// The refresh-token table and access-token table live in `accounts.dart` so
/// the OTP verify path (registration success) and `profile` can share them.
void registerRoutes(Router router) {
  router.post('/v1/auth/issue', _issue);
  router.post('/v1/auth/register', _register);
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
  final userId = userIdForEmail(email);
  return Response.ok(
    jsonEncode(<String, Object>{
      'accessToken': issueAccessToken(userId),
      'refreshToken': issueRefreshToken(userId),
      'expiresAt': _now().add(accessTtl).toIso8601String(),
      'userId': userId,
    }),
    headers: _jsonHeaders,
  );
}

Future<Response> _register(Request request) async {
  final decoded = await _decode(request);
  if (decoded == null) {
    return _invalid();
  }
  final email = decoded['email'];
  final password = decoded['password'];
  final displayName = decoded['displayName'];
  if (email is! String ||
      email.isEmpty ||
      password is! String ||
      password.isEmpty ||
      displayName is! String ||
      displayName.isEmpty) {
    return _invalid();
  }
  // A pending (unverified) OR active account for this email blocks a fresh
  // registration — the client must verify or recover instead.
  if (accountExists(email)) {
    return Response(
      409,
      body: jsonEncode(<String, String>{'error': 'conflict'}),
      headers: _jsonHeaders,
    );
  }
  createPendingAccount(email: email, password: password, displayName: displayName);
  // Hand the OTP issue to the OTP module so there is one source of truth for
  // attempt tokens, code generation, and the dev_code affordance.
  final envelope = otp.issueOtpEnvelope(
    purpose: 'registration',
    identifier: email,
    isDev: _isDevRequest(request),
  );
  return Response.ok(jsonEncode(envelope), headers: _jsonHeaders);
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
  final rotated = rotateRefreshToken(presented);
  if (rotated == null) {
    return _unauthorized();
  }
  return Response.ok(
    jsonEncode(<String, Object>{
      'accessToken': issueAccessToken(rotated.userId),
      'refreshToken': rotated.refreshToken,
      'expiresAt': _now().add(accessTtl).toIso8601String(),
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
      revokeRefreshToken(presented);
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
