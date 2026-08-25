import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:starter/features/notifications/notifications_repository.dart';
import 'package:starter/infrastructure/http/app_http_repository.dart';
import 'package:starter/infrastructure/notifications/notifications_registration.dart';

final class HttpNotificationsRegistrationClient extends AppHttpRepository
    implements NotificationsRegistration {
  HttpNotificationsRegistrationClient({required super.baseUrl, super.dio});

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

  @override
  Never classify(int status) {
    if (status >= 400 && status < 500) {
      throw const NotificationsException.unknown();
    }
    throw const NotificationsException.notConnected();
  }

  @override
  Never throwNotConnected() => throw const NotificationsException.notConnected();

  Future<void> _post({required String path, required Map<String, Object> body}) async {
    await _roundTrip(
      () => dio.post<String>(
        path,
        data: jsonEncode(body),
        options: Options(responseType: ResponseType.plain, contentType: Headers.jsonContentType),
      ),
    );
  }

  Future<void> _delete(String path) async {
    await _roundTrip(
      () => dio.delete<String>(path, options: Options(responseType: ResponseType.plain)),
    );
  }

  Future<void> _roundTrip(Future<Response<String>> Function() send) async {
    final response = await roundTripRaw(send);
    final status = response.statusCode!;
    if (status >= 200 && status < 300) return;
    classify(status);
  }
}
