import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/notifications/notifications_repository.dart';
import 'package:starter/infrastructure/http/app_dio.dart';
import 'package:starter/infrastructure/notifications/http_notifications_registration_client.dart';

Future<({Uri baseUri, Future<void> Function() tearDown, Set<String> registered})> _bootServer({
  int statusCode = 204,
}) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final registered = <String>{};
  unawaited(
    server.forEach((request) async {
      final path = request.uri.path;
      if (path == '/v1/notifications/register-token') {
        registered.add(request.uri.toString());
      }
      try {
        await request.drain<void>();
      } on Object {
        // ignored
      }
      request.response.statusCode = statusCode;
      await request.response.close();
    }),
  );
  return (
    baseUri: Uri.parse('http://${server.address.host}:${server.port}'),
    tearDown: server.close,
    registered: registered,
  );
}

void main() {
  group('HttpNotificationsRegistrationClient', () {
    test('registerToken succeeds against a 2xx endpoint', () async {
      final boot = await _bootServer();
      addTearDown(boot.tearDown);
      final client = HttpNotificationsRegistrationClient(
        baseUrl: boot.baseUri,
        dio: buildAppDio(boot.baseUri),
      );
      await expectLater(
        client.registerToken(token: 't', platform: 'ios', deviceId: 'd'),
        completes,
      );
      expect(boot.registered, isNotEmpty);
    });

    test('unregisterToken succeeds against a 2xx endpoint', () async {
      final boot = await _bootServer();
      addTearDown(boot.tearDown);
      final client = HttpNotificationsRegistrationClient(
        baseUrl: boot.baseUri,
        dio: buildAppDio(boot.baseUri),
      );
      await expectLater(client.unregisterToken('t'), completes);
    });

    test('reportPermissionRevoked succeeds against a 2xx endpoint', () async {
      final boot = await _bootServer();
      addTearDown(boot.tearDown);
      final client = HttpNotificationsRegistrationClient(
        baseUrl: boot.baseUri,
        dio: buildAppDio(boot.baseUri),
      );
      await expectLater(client.reportPermissionRevoked(deviceId: 'd'), completes);
    });

    test('a 4xx response surfaces NotificationsException.unknown', () async {
      final boot = await _bootServer(statusCode: 400);
      addTearDown(boot.tearDown);
      final client = HttpNotificationsRegistrationClient(
        baseUrl: boot.baseUri,
        dio: buildAppDio(boot.baseUri),
      );
      await expectLater(
        client.registerToken(token: 't', platform: 'ios', deviceId: 'd'),
        throwsA(
          isA<NotificationsException>().having(
            (e) => e.kind,
            'kind',
            NotificationsFailureKind.unknown,
          ),
        ),
      );
    });

    test('a 5xx response surfaces NotificationsException.notConnected', () async {
      final boot = await _bootServer(statusCode: 503);
      addTearDown(boot.tearDown);
      final client = HttpNotificationsRegistrationClient(
        baseUrl: boot.baseUri,
        dio: buildAppDio(boot.baseUri),
      );
      await expectLater(
        client.registerToken(token: 't', platform: 'ios', deviceId: 'd'),
        throwsA(
          isA<NotificationsException>().having(
            (e) => e.kind,
            'kind',
            NotificationsFailureKind.notConnected,
          ),
        ),
      );
    });

    test('an unreachable server surfaces notConnected (SocketException)', () async {
      final sink = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final port = sink.port;
      await sink.close();
      final dead = Uri.parse('http://${InternetAddress.loopbackIPv4.address}:$port');
      final client = HttpNotificationsRegistrationClient(baseUrl: dead, dio: buildAppDio(dead));
      await expectLater(
        client.registerToken(token: 't', platform: 'ios', deviceId: 'd'),
        throwsA(
          isA<NotificationsException>().having(
            (e) => e.kind,
            'kind',
            NotificationsFailureKind.notConnected,
          ),
        ),
      );
    });
  });
}
