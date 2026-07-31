import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/force_update/remote_config_version_gate_store.dart';
import 'package:starter/features/force_update/update_requirement.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';

void main() {
  late HttpServer server;

  tearDown(() async {
    await server.close(force: true);
  });

  Future<HttpServer> startServer({required int status, Object? body}) async {
    final bound = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    return server = bound
      ..listen((request) async {
        final response = request.response
          ..statusCode = status
          ..headers.contentType = ContentType.json;
        if (body != null) {
          response.write(jsonEncode(body));
        }
        await response.close();
      });
  }

  AppBuildInfo buildInfo(String version) => AppBuildInfo(version: version, buildNumber: '1');

  RemoteConfigVersionGateStore storeFor(
    HttpServer server, {
    Duration timeout = const Duration(seconds: 2),
  }) {
    final authority = '${server.address.host}:${server.port}';
    return RemoteConfigVersionGateStore(
      baseUrl: Uri.http(authority, '/'),
      timeout: timeout,
    );
  }

  const versionPolicy = <String, Object?>{
    'minVersion': null,
    'latestVersion': null,
    'hardBlockBelow': null,
    'softBlockBelow': null,
    'storeUrl': null,
    'message': null,
  };

  Object? payload(Map<String, Object?> policy) => <String, Object?>{
    'flags': <String, Object?>{},
    'versionPolicy': policy,
    'experiments': <String, Object?>{},
    'revision': '1',
  };

  test('hard block when installed below hardBlockBelow', () async {
    await startServer(
      status: 200,
      body: payload({
        ...versionPolicy,
        'minVersion': '2.0.0',
        'latestVersion': '2.1.0',
        'hardBlockBelow': '2.0.0',
        'storeUrl': 'https://example.test/store',
        'message': 'security fix',
      }),
    );
    final result = await storeFor(server).check(buildInfo('1.4.0'));
    expect(result, isA<UpdateRequirementHard>());
    final hard = result as UpdateRequirementHard;
    expect(hard.minVersion, '2.0.0');
    expect(hard.latestVersion, '2.1.0');
    expect(hard.storeUrl, 'https://example.test/store');
    expect(hard.message, 'security fix');
  });

  test('soft block when installed below softBlockBelow but at/above hard', () async {
    await startServer(
      status: 200,
      body: payload({
        ...versionPolicy,
        'latestVersion': '1.5.0',
        'hardBlockBelow': '1.0.0',
        'softBlockBelow': '1.4.0',
        'storeUrl': 'https://example.test/store',
      }),
    );
    final result = await storeFor(server).check(buildInfo('1.2.0'));
    expect(result, isA<UpdateRequirementSoft>());
    final soft = result as UpdateRequirementSoft;
    expect(soft.minVersion, '1.4.0');
    expect(soft.latestVersion, '1.5.0');
  });

  test('none when installed meets every threshold', () async {
    await startServer(
      status: 200,
      body: payload({
        ...versionPolicy,
        'hardBlockBelow': '2.0.0',
        'softBlockBelow': '2.4.0',
        'storeUrl': 'https://example.test/store',
        'latestVersion': '2.5.0',
      }),
    );
    expect(
      await storeFor(server).check(buildInfo('2.5.0')),
      const UpdateRequirementNone(),
    );
  });

  test('pre-release is ordered below the release of the same version', () async {
    await startServer(
      status: 200,
      body: payload({
        ...versionPolicy,
        'hardBlockBelow': '1.0.0',
        'softBlockBelow': '2.4.0',
        'storeUrl': 'https://example.test/store',
        'latestVersion': '2.4.0',
      }),
    );
    final result = await storeFor(server).check(buildInfo('2.4.0-dev'));
    expect(result, isA<UpdateRequirementSoft>());
  });

  test('none when policy lacks a storeUrl (cannot offer an update path)', () async {
    await startServer(
      status: 200,
      body: payload({
        ...versionPolicy,
        'hardBlockBelow': '2.0.0',
        'storeUrl': null,
      }),
    );
    final store = storeFor(server);
    expect(await store.check(buildInfo('1.0.0')), const UpdateRequirementNone());
    expect(store.storeUrl, isNull);
  });

  test('none on non-200 without faking a block', () async {
    await startServer(
      status: 503,
      body: const <String, Object?>{'error': 'down'},
    );
    expect(
      await storeFor(server).check(buildInfo('1.0.0')),
      const UpdateRequirementNone(),
    );
  });

  test('none when installed version is not semver', () async {
    await startServer(
      status: 200,
      body: payload({
        ...versionPolicy,
        'hardBlockBelow': '2.0.0',
        'storeUrl': 'https://example.test/store',
      }),
    );
    expect(
      await storeFor(server).check(buildInfo('not-a-version')),
      const UpdateRequirementNone(),
    );
  });

  test('hard wins over soft when both thresholds apply', () async {
    await startServer(
      status: 200,
      body: payload({
        ...versionPolicy,
        'hardBlockBelow': '2.0.0',
        'softBlockBelow': '1.5.0',
        'storeUrl': 'https://example.test/store',
        'latestVersion': '2.5.0',
      }),
    );
    expect(
      await storeFor(server).check(buildInfo('1.0.0')),
      isA<UpdateRequirementHard>(),
    );
  });

  test('exposes the storeUrl from the last successful policy read', () async {
    await startServer(
      status: 200,
      body: payload({
        ...versionPolicy,
        'softBlockBelow': '1.4.0',
        'storeUrl': 'https://example.test/store',
        'latestVersion': '1.5.0',
      }),
    );
    final store = storeFor(server);
    await store.check(buildInfo('1.2.0'));
    expect(store.storeUrl, 'https://example.test/store');
  });

  test('none on an unreachable host (connect failure degrades honestly)', () async {
    final store = RemoteConfigVersionGateStore(
      baseUrl: Uri.http('127.0.0.1:1', '/'),
      timeout: const Duration(milliseconds: 50),
    );
    expect(
      await store.check(buildInfo('1.0.0')),
      const UpdateRequirementNone(),
    );
  });
}
