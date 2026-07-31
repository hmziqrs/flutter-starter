import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:starter/features/profile/profile_repository.dart';
import 'package:starter/features/profile/profile_view_data.dart';
import 'package:starter/infrastructure/http/app_dio.dart';

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
    final bio = body['bio'];
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
