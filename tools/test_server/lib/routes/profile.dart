import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../accounts.dart';

const Map<String, String> _jsonHeaders = <String, String>{
  'content-type': 'application/json; charset=utf-8',
};

/// Mounts the profile contract onto [router]:
/// - `GET /v1/profile`  -> `200 {displayName, username, email, bio}` for the
///   Bearer token's user, or `401` if the token is missing/unknown.
/// - `PUT /v1/profile`  `{displayName?, bio?}` -> `200 {displayName, username, email, bio}`
///   (email is read-only and ignored if sent), or `401`.
///
/// Auth is Bearer: the header must be `Authorization: Bearer <accessToken>`
/// where the access token was issued by `/v1/auth/issue` or a registration
/// verify. Access tokens resolve to a user id via `accounts.dart`; the profile
/// shape is then read from the account record (so a token without an account —
/// e.g. a magic-login user with no profile — yields 401).
void registerRoutes(Router router) {
  router.get('/v1/profile', _get);
  router.put('/v1/profile', _put);
}

/// Resolves the Bearer token on [request] to the authenticated account, or
/// returns `null` when the token is missing, malformed, unknown, or has no
/// account record.
Account? _authenticate(Request request) {
  final header = request.headers['authorization'];
  if (header == null) {
    return null;
  }
  final parts = header.split(' ');
  if (parts.length != 2 || parts[0] != 'Bearer') {
    return null;
  }
  final userId = userIdForAccessToken(parts[1]);
  if (userId == null) {
    return null;
  }
  return findAccountByUserId(userId);
}

/// Builds the camelCase profile shape (matches the auth convention). `username`
/// is the email's local-part; `bio` starts empty and is mutated by PUT.
Map<String, String> _profileShape(Account account) {
  final at = account.email.indexOf('@');
  final username = at > 0 ? account.email.substring(0, at) : account.email;
  return <String, String>{
    'displayName': account.displayName,
    'username': username,
    'email': account.email,
    'bio': account.bio,
  };
}

Future<Response> _get(Request request) async {
  final account = _authenticate(request);
  if (account == null) {
    return _unauthorized();
  }
  return Response.ok(jsonEncode(_profileShape(account)), headers: _jsonHeaders);
}

Future<Response> _put(Request request) async {
  final account = _authenticate(request);
  if (account == null) {
    return _unauthorized();
  }
  final decoded = await _decode(request);
  if (decoded == null) {
    return _invalid();
  }
  final displayName = decoded['displayName'];
  if (displayName is String && displayName.isNotEmpty) {
    account.displayName = displayName;
  }
  final bio = decoded['bio'];
  // bio may be explicitly cleared to empty, so accept any string (including '').
  if (bio is String) {
    account.bio = bio;
  }
  // email is read-only — deliberately ignored if the client sends it.
  return Response.ok(jsonEncode(_profileShape(account)), headers: _jsonHeaders);
}

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
