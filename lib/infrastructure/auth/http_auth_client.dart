import 'dart:convert';
import 'dart:io';

// The private-field constructor with a public-named required parameter is the
// mandated shape (mirrors `HttpNotificationsRegistrationClient`); initializing
// formals would rename the public parameter.
// ignore_for_file: prefer_initializing_formals

import 'package:starter/features/auth/otp_repository.dart';
import 'package:starter/features/session/auth_repository.dart';
import 'package:starter/features/session/auth_session.dart';

/// Real HTTP [AuthRepository] against the test-server session contract (C9).
///
/// Constructed **only when a consumer provides an endpoint** (the no-backend
/// rule, C2: the `InMemoryAuthRepository` default surfaces
/// `AuthException.notConnected` and never fakes a session). Mirrors
/// `HttpNotificationsRegistrationClient`: uses `dart:io` `HttpClient` (no extra
/// package) because the test / dev graph runs on native only; web falls through
/// to the in-memory default per `PlatformCapabilities`.
///
/// Every interaction is wrapped in `try/on` and mapped to a typed
/// [AuthException] — transport failures surface [AuthException.notConnected],
/// `401`/`409` surface [AuthException.unauthorized], any other `4xx` surfaces
/// [AuthException.unknown], and a `5xx`/unclassified response surfaces
/// [AuthException.notConnected]. The client never fabricates a session (C2).
///
/// Tokens reach this class only after the `LogRedactor`-scrubbed logging path;
/// this class itself does not log token values (it surfaces only the typed
/// outcome).
final class HttpAuthClient implements AuthRepository {
  HttpAuthClient({required Uri baseUrl, HttpClient? httpClient})
    : _baseUrl = baseUrl,
      _httpClient = httpClient ?? HttpClient();

  final Uri _baseUrl;
  final HttpClient _httpClient;

  @override
  Future<AuthSession> login(AuthCredentials credentials) async {
    final body = await _request(
      method: 'POST',
      path: '/v1/auth/issue',
      body: <String, Object>{
        'email': credentials.email,
        'password': credentials.password,
      },
    );
    return _parseAuthenticated(body);
  }

  @override
  Future<OtpIssueResult> register({
    required AuthCredentials credentials,
    required String displayName,
  }) async {
    final body = await _request(
      method: 'POST',
      path: '/v1/auth/register',
      body: <String, Object>{
        'email': credentials.email,
        'password': credentials.password,
        'displayName': displayName,
      },
      extraHeaders: <String, String>{'X-Api-Key': 'dev'},
    );
    return _parseIssueEnvelope(body);
  }

  @override
  Future<AuthSession> refresh(AuthSession session) async {
    if (session is! AuthAuthenticated) {
      // An anonymous session carries no refresh token to present; the caller
      // treats this like any other unauthorized refresh outcome.
      throw const AuthException.unauthorized();
    }
    final body = await _request(
      method: 'POST',
      path: '/v1/auth/refresh',
      body: <String, Object>{'refreshToken': session.refreshToken},
    );
    final accessToken = _asString(body['accessToken']);
    final refreshToken = _asString(body['refreshToken']);
    final expiresAt = _parseDate(body['expiresAt']);
    if (accessToken == null || refreshToken == null || expiresAt == null) {
      throw const AuthException.unknown();
    }
    // The refresh response omits `userId`; the identity is inherited across
    // token rotations (see AuthAuthenticated docs).
    return AuthAuthenticated(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
      userId: session.userId,
    );
  }

  @override
  Future<AuthSession> logout(AuthSession session) async {
    final refreshToken = session is AuthAuthenticated ? session.refreshToken : null;
    // Logout is idempotent and best-effort: a transport failure surfaces as
    // AuthException.notConnected, but the caller clears local state regardless
    // (a failed logout must not strand the user in an authenticated shell).
    final body = <String, Object>{};
    if (refreshToken != null) {
      body['refreshToken'] = refreshToken;
    }
    await _request(method: 'POST', path: '/v1/auth/logout', body: body);
    return const AuthAnonymous();
  }

  // --------------------------- HTTP plumbing ----------------------------

  Future<Map<String, Object?>> _request({
    required String method,
    required String path,
    required Map<String, Object> body,
    Map<String, String> extraHeaders = const <String, String>{},
  }) async {
    final uri = _resolve(path);
    final request = await _openRequest(method, uri);
    request.headers.contentType = ContentType.json;
    for (final entry in extraHeaders.entries) {
      request.headers.add(entry.key, entry.value);
    }
    request.write(jsonEncode(body));
    final HttpClientResponse response;
    String responseBody;
    try {
      response = await request.close();
      responseBody = await response.transform(utf8.decoder).join();
    } on SocketException {
      throw const AuthException.notConnected();
    } on HttpException {
      throw const AuthException.notConnected();
    } on Object {
      throw const AuthException.notConnected();
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (responseBody.isEmpty) return const <String, Object?>{};
      return _decodeJson(responseBody);
    }
    _classifyStatus(response.statusCode);
  }

  Uri _resolve(String path) {
    final base = _baseUrl.replace(path: '${_baseUrl.path}$path'.replaceAll('//', '/'));
    return base;
  }

  Future<HttpClientRequest> _openRequest(String method, Uri uri) async {
    try {
      return await _httpClient.openUrl(method, uri);
    } on SocketException catch (_) {
      throw const AuthException.notConnected();
    } on HttpException catch (_) {
      throw const AuthException.notConnected();
    } on Object catch (_) {
      throw const AuthException.unknown();
    }
  }

  Never _classifyStatus(int status) {
    if (status == HttpStatus.unauthorized || status == HttpStatus.conflict) {
      throw const AuthException.unauthorized();
    }
    if (status >= 400 && status < 500) {
      throw const AuthException.unknown();
    }
    throw const AuthException.notConnected();
  }

  AuthAuthenticated _parseAuthenticated(Map<String, Object?> body) {
    final accessToken = _asString(body['accessToken']);
    final refreshToken = _asString(body['refreshToken']);
    final expiresAt = _parseDate(body['expiresAt']);
    final userId = _asString(body['userId']);
    if (accessToken == null || refreshToken == null || expiresAt == null || userId == null) {
      throw const AuthException.unknown();
    }
    return AuthAuthenticated(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
      userId: userId,
    );
  }

  OtpIssueResult _parseIssueEnvelope(Map<String, Object?> body) {
    final attemptToken = _asString(body['attempt_token']);
    final expiresAt = _parseDate(body['expires_at']);
    if (attemptToken == null || expiresAt == null) {
      throw const AuthException.unknown();
    }
    return OtpIssueResult(
      expiresAt: expiresAt,
      channel: _parseChannel(body['channel']),
      attemptToken: attemptToken,
    );
  }

  static OtpDeliveryChannel _parseChannel(Object? raw) {
    return switch (raw) {
      'sms' => OtpDeliveryChannel.sms,
      'email' => OtpDeliveryChannel.email,
      _ => OtpDeliveryChannel.authenticator,
    };
  }

  static Map<String, Object?> _decodeJson(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, Object?>) {
        return decoded;
      }
    } on FormatException {
      throw const AuthException.unknown();
    }
    throw const AuthException.unknown();
  }

  static String? _asString(Object? raw) => raw is String && raw.isNotEmpty ? raw : null;

  static DateTime? _parseDate(Object? raw) {
    if (raw is! String || raw.isEmpty) return null;
    try {
      return DateTime.parse(raw);
    } on FormatException {
      return null;
    }
  }
}
