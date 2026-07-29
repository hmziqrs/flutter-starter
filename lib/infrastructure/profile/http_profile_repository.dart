import 'dart:convert';
import 'dart:io';

// The private-field constructor with a public-named required parameter is the
// mandated shape (mirrors `HttpNotificationsRegistrationClient` /
// `HttpAuthClient`); initializing formals would rename the public parameter.
// ignore_for_file: prefer_initializing_formals

import 'package:starter/features/profile/profile_repository.dart';
import 'package:starter/features/profile/profile_view_data.dart';

/// Real HTTP [ProfileRepository] against the test-server profile contract (C9).
///
/// Constructed **only when a consumer provides an endpoint** (the no-backend
/// rule, C2): until then the UI degrades to `ProfileDraft.defaults()` and never
/// fabricates a backend-sourced profile. Mirrors `HttpAuthClient`: uses
/// `dart:io` `HttpClient` (no extra package), native-only.
///
/// `load` performs `GET /v1/profile`; `save` performs `PUT /v1/profile` with
/// `{displayName, bio}` (email is read-only and omitted from the write body).
/// Both authorize with `Authorization: Bearer <accessToken>`. Every interaction
/// is wrapped in `try/on` and mapped to a typed [ProfileException]: transport
/// failures and `401` (unaccepted session) surface
/// [ProfileException.notConnected] so the caller degrades to a local default;
/// any other `4xx` surfaces [ProfileException.unknown]; a `5xx`/unclassified
/// response surfaces [ProfileException.notConnected] (C2: degrade, never fake).
final class HttpProfileRepository implements ProfileRepository {
  HttpProfileRepository({required Uri baseUrl, HttpClient? httpClient})
    : _baseUrl = baseUrl,
      _httpClient = httpClient ?? HttpClient();

  final Uri _baseUrl;
  final HttpClient _httpClient;

  @override
  Future<ProfileDraft> load({required String accessToken}) async {
    final body = await _send(
      method: 'GET',
      path: '/v1/profile',
      accessToken: accessToken,
    );
    return _parseProfile(body);
  }

  @override
  Future<ProfileDraft> save({required String accessToken, required ProfileDraft draft}) async {
    final body = await _send(
      method: 'PUT',
      path: '/v1/profile',
      accessToken: accessToken,
      body: <String, Object>{'displayName': draft.displayName, 'bio': draft.bio},
    );
    return _parseProfile(body);
  }

  // --------------------------- HTTP plumbing ----------------------------

  Future<Map<String, Object?>> _send({
    required String method,
    required String path,
    required String accessToken,
    Map<String, Object>? body,
  }) async {
    final uri = _resolve(path);
    final request = await _openRequest(method, uri);
    request.headers.add('Authorization', 'Bearer $accessToken');
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
    }
    final HttpClientResponse response;
    String responseBody;
    try {
      response = await request.close();
      responseBody = await response.transform(utf8.decoder).join();
    } on SocketException {
      throw const ProfileException.notConnected();
    } on HttpException {
      throw const ProfileException.notConnected();
    } on Object {
      throw const ProfileException.notConnected();
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
      throw const ProfileException.notConnected();
    } on HttpException catch (_) {
      throw const ProfileException.notConnected();
    } on Object catch (_) {
      throw const ProfileException.unknown();
    }
  }

  Never _classifyStatus(int status) {
    // 401 (unaccepted session) folds into the notConnected bucket so the caller
    // degrades to a local default — ProfileException has no `unauthorized` kind
    // by design (the profile screen never surfaces an auth-challenge UI itself;
    // it degrades and lets the session layer handle re-auth).
    if (status == HttpStatus.unauthorized || status >= 500) {
      throw const ProfileException.notConnected();
    }
    if (status >= 400 && status < 500) {
      throw const ProfileException.unknown();
    }
    throw const ProfileException.notConnected();
  }

  ProfileDraft _parseProfile(Map<String, Object?> body) {
    final displayName = _asString(body['displayName']);
    final username = _asString(body['username']);
    final email = _asString(body['email']);
    final bio = body['bio']; // bio may be an explicitly-cleared empty string.
    if (displayName == null || username == null || email == null || bio is! String) {
      throw const ProfileException.unknown();
    }
    return ProfileDraft(
      displayName: displayName,
      username: username,
      email: email,
      bio: bio,
    );
  }

  static Map<String, Object?> _decodeJson(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, Object?>) {
        return decoded;
      }
    } on FormatException {
      throw const ProfileException.unknown();
    }
    throw const ProfileException.unknown();
  }

  static String? _asString(Object? raw) => raw is String && raw.isNotEmpty ? raw : null;
}
