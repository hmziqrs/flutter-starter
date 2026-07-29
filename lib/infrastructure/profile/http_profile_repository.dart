import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:starter/features/profile/profile_repository.dart';
import 'package:starter/features/profile/profile_view_data.dart';
import 'package:starter/infrastructure/http/app_dio.dart';

/// Real HTTP [ProfileRepository] against the test-server profile contract (C9).
///
/// Constructed **only when a consumer provides an endpoint** (the no-backend
/// rule, C2): until then the UI degrades to `ProfileDraft.defaults()` and never
/// fabricates a backend-sourced profile. Mirrors `HttpAuthClient`: speaks to the
/// backend through a shared injected [Dio] (built via [buildAppDio] when no
/// instance is supplied), native-only.
///
/// `load` performs `GET /v1/profile`; `save` performs `PUT /v1/profile` with
/// `{displayName, bio}` (email is read-only and omitted from the write body).
/// Both authorize with `Authorization: Bearer <accessToken>`. Every interaction
/// is wrapped in `try/on` and mapped to a typed [ProfileException]: transport
/// failures (any [DioException] without a response) and `401` (unaccepted
/// session) surface [ProfileException.notConnected] so the caller degrades to a
/// local default; any other `4xx` surfaces [ProfileException.unknown]; a
/// `5xx`/unclassified response surfaces [ProfileException.notConnected] (C2:
/// degrade, never fake).
final class HttpProfileRepository implements ProfileRepository {
  HttpProfileRepository({required Uri baseUrl, Dio? dio}) : _dio = dio ?? buildAppDio(baseUrl);

  final Dio _dio;

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
    final Response<String> response;
    try {
      response = await _dio.request<String>(
        path,
        data: body == null ? null : jsonEncode(body),
        options: Options(
          method: method,
          responseType: ResponseType.plain,
          contentType: body == null ? null : Headers.jsonContentType,
          headers: <String, String>{'Authorization': 'Bearer $accessToken'},
        ),
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status != null) {
        _classifyStatus(status);
      }
      throw const ProfileException.notConnected();
    }
    final status = response.statusCode!;
    if (status >= 200 && status < 300) {
      final responseBody = response.data ?? '';
      if (responseBody.isEmpty) return const <String, Object?>{};
      return _decodeJson(responseBody);
    }
    _classifyStatus(status);
  }

  Never _classifyStatus(int status) {
    // 401 (unaccepted session) folds into the notConnected bucket so the caller
    // degrades to a local default — ProfileException has no `unauthorized` kind
    // by design (the profile screen never surfaces an auth-challenge UI itself;
    // it degrades and lets the session layer handle re-auth).
    if (status == 401 || status >= 500) {
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
