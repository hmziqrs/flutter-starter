import 'dart:convert';

// Doc comments intentionally reference sibling feature-package types.
// ignore_for_file: comment_references

import 'package:dio/dio.dart';
import 'package:starter/features/notifications/notifications_repository.dart';
import 'package:starter/infrastructure/http/app_dio.dart';
import 'package:starter/infrastructure/notifications/notifications_registration.dart';

/// Real HTTP [NotificationsRegistration] client against the test-server push
/// contract. Constructed only in the test/dev graph or by
/// `FirebaseNotificationsRepository` when a consumer passes a configured
/// endpoint; never in `AppDependencies.production` directly (the
/// [NoopNotificationsRepository] is the production default).
final class HttpNotificationsRegistrationClient implements NotificationsRegistration {
  HttpNotificationsRegistrationClient({required Uri baseUrl, Dio? dio})
    : _dio = dio ?? buildAppDio(baseUrl);

  final Dio _dio;

  @override
  Future<void> registerToken({
    required String token,
    required String platform,
    required String deviceId,
  }) async {
    await _post(
      path: '/v1/notifications/register-token',
      body: <String, Object>{
        'token': token,
        'platform': platform,
        'deviceId': deviceId,
      },
    );
  }

  @override
  Future<void> unregisterToken(String token) async {
    await _delete('/v1/notifications/register-token/${Uri.encodeComponent(token)}');
  }

  @override
  Future<void> reportPermissionRevoked({required String deviceId}) async {
    await _post(
      path: '/v1/notifications/permission-revoked',
      body: <String, Object>{'deviceId': deviceId},
    );
  }

  Future<void> _post({required String path, required Map<String, Object> body}) async {
    await _roundTrip(
      () => _dio.post<String>(
        path,
        data: jsonEncode(body),
        options: Options(responseType: ResponseType.plain, contentType: Headers.jsonContentType),
      ),
    );
  }

  Future<void> _delete(String path) async {
    await _roundTrip(
      () => _dio.delete<String>(path, options: Options(responseType: ResponseType.plain)),
    );
  }

  /// 2xx succeeds; 4xx surfaces [NotificationsException.unknown]; anything
  /// else (5xx / transport) surfaces [NotificationsException.notConnected].
  Future<void> _roundTrip(Future<Response<String>> Function() send) async {
    final Response<String> response;
    try {
      response = await send();
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status != null) {
        _ensureSuccess(status);
      }
      throw const NotificationsException.notConnected();
    }
    _ensureSuccess(response.statusCode!);
  }

  void _ensureSuccess(int status) {
    if (status >= 200 && status < 300) return;
    if (status >= 400 && status < 500) {
      throw const NotificationsException.unknown();
    }
    throw const NotificationsException.notConnected();
  }
}
