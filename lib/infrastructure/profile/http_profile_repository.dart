import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:starter/features/profile/profile_repository.dart';
import 'package:starter/features/profile/profile_view_data.dart';
import 'package:starter/infrastructure/http/app_http_repository.dart';
import 'package:starter/infrastructure/http/json_body.dart';

final class HttpProfileRepository extends AppHttpRepository implements ProfileRepository {
  HttpProfileRepository({required super.baseUrl, super.dio});

  @override
  Future<ProfileDraft> load({required String accessToken}) async {
    final body = await _send(method: 'GET', path: '/v1/profile', accessToken: accessToken);
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

  @override
  Never classify(int status) {
    if (status == 401 || status >= 500) {
      throw const ProfileException.notConnected();
    }
    if (status >= 400 && status < 500) {
      throw const ProfileException.unknown();
    }
    throw const ProfileException.notConnected();
  }

  @override
  Never throwNotConnected() => throw const ProfileException.notConnected();

  Future<Map<String, Object?>> _send({
    required String method,
    required String path,
    required String accessToken,
    Map<String, Object>? body,
  }) async {
    final response = await roundTripRaw(
      () => dio.request<String>(
        path,
        data: body == null ? null : jsonEncode(body),
        options: Options(
          method: method,
          responseType: ResponseType.plain,
          contentType: body == null ? null : Headers.jsonContentType,
          headers: <String, String>{'Authorization': 'Bearer $accessToken'},
        ),
      ),
    );
    final status = response.statusCode!;
    if (status >= 200 && status < 300) {
      return decodeJsonMap(response, errorFactory: (_) => throw const ProfileException.unknown());
    }
    classify(status);
  }

  ProfileDraft _parseProfile(Map<String, Object?> body) {
    final displayName = asString(body['displayName']);
    final username = asString(body['username']);
    final email = asString(body['email']);
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
}
