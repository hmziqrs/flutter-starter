import 'dart:convert';
import 'dart:io';

// `comment_references` flags doc cross-references to sibling-class names
// (NotificationsException etc.) imported only via the feature package; the
// references are intentional. The private-field constructor with a
// public-named required parameter is the same shape as the firebase adapter.
// ignore_for_file: prefer_initializing_formals, comment_references

import 'package:starter/features/notifications/notifications_repository.dart';
import 'package:starter/infrastructure/notifications/notifications_registration.dart';

/// Real HTTP [NotificationsRegistration] client against the test-server push
/// contract (C9).
///
/// Constructed **only in the test / dev graph** (integration tests point it at
/// a random-port test server; the development config may point it at a fixed
/// local URL). It is never constructed in `AppDependencies.production` — the
/// [NoopNotificationsRepository] is the production default, and the optional
/// `FirebaseNotificationsRepository` wires its own registration client only
/// when a consumer passes a configured endpoint. Uses `dart:io` `HttpClient`
/// (no extra package) because the test / dev graph runs on native only; web
/// falls through to the Noop default per `PlatformCapabilities`.
///
/// Token / deviceId values reach this class only after the
/// `LogRedactor`-scrubbed logging path inside the Firebase adapter; this class
/// itself does not log the values (it logs only the round-trip outcome).
final class HttpNotificationsRegistrationClient implements NotificationsRegistration {
  HttpNotificationsRegistrationClient({required Uri baseUrl, HttpClient? httpClient})
    : _baseUrl = baseUrl,
      _httpClient = httpClient ?? HttpClient();

  final Uri _baseUrl;
  final HttpClient _httpClient;

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
    final uri = _resolve(path);
    final request = await _openRequest('POST', uri);
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode(body));
    await _roundTrip(request);
  }

  Future<void> _delete(String path) async {
    final uri = _resolve(path);
    final request = await _openRequest('DELETE', uri);
    await _roundTrip(request);
  }

  Uri _resolve(String path) {
    final base = _baseUrl.replace(path: '${_baseUrl.path}$path'.replaceAll('//', '/'));
    return base;
  }

  Future<HttpClientRequest> _openRequest(String method, Uri uri) async {
    try {
      return await _httpClient.openUrl(method, uri);
    } on SocketException catch (_) {
      throw const NotificationsException.notConnected();
    } on HttpException catch (_) {
      throw const NotificationsException.notConnected();
    } on Object catch (_) {
      throw const NotificationsException.unknown();
    }
  }

  Future<void> _roundTrip(HttpClientRequest request) async {
    final response = await request.close();
    try {
      // Drain so the socket can be reused; the body is unused (the contract
      // is 204 / 4xx — no payload to surface).
      await response.drain<void>();
    } on Object {
      // Drain failure does not change the outcome classification below.
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    if (response.statusCode >= 400 && response.statusCode < 500) {
      throw const NotificationsException.unknown();
    }
    throw const NotificationsException.notConnected();
  }
}
