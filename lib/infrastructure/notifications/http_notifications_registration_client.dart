import 'dart:convert';

// `comment_references` flags doc cross-references to sibling-class names
// (NotificationsException etc.) imported only via the feature package; the
// references are intentional.
// ignore_for_file: comment_references

import 'package:dio/dio.dart';
import 'package:starter/features/notifications/notifications_repository.dart';
import 'package:starter/infrastructure/http/app_dio.dart';
import 'package:starter/infrastructure/notifications/notifications_registration.dart';

/// Real HTTP [NotificationsRegistration] client against the test-server push
/// contract (C9).
///
/// Constructed **only in the test / dev graph** (integration tests point it at
/// a random-port test server; the development config may point it at a fixed
/// local URL). It is never constructed in `AppDependencies.production` — the
/// [NoopNotificationsRepository] is the production default, and the optional
/// `FirebaseNotificationsRepository` wires its own registration client only
/// when a consumer passes a configured endpoint. Speaks to the backend through
/// a shared injected [Dio] (built via [buildAppDio] when no instance is
/// supplied); web falls through to the Noop default per `PlatformCapabilities`.
///
/// Token / deviceId values reach this class only after the
/// `LogRedactor`-scrubbed logging path inside the Firebase adapter; this class
/// itself does not log the values (it logs only the round-trip outcome).
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

  /// Sends the request and classifies the outcome. The body is unused (the
  /// contract is 204 / 4xx — no payload to surface): 2xx succeeds, a 4xx
  /// surfaces [NotificationsException.unknown], anything else (5xx / transport)
  /// surfaces [NotificationsException.notConnected].
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
