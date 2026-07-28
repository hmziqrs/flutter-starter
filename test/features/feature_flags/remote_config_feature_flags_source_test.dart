import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/feature_flags/feature_flags.dart';
import 'package:starter/features/feature_flags/in_memory_feature_flags_source.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';
import 'package:starter/infrastructure/remote_config/remote_config_client.dart';
import 'package:starter/infrastructure/remote_config/remote_config_feature_flags_source.dart';

void main() {
  const buildInfo = AppBuildInfo(version: '1.0.0', buildNumber: '1');

  late HttpServer server;

  tearDown(() async {
    await server.close(force: true);
  });

  /// Status code and body the stub server returns on the next request.
  int? nextStatus;
  Object? nextBody;

  Future<HttpServer> startServer() async {
    final bound = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    return server = bound
      ..listen((request) async {
        final response = request.response
          ..statusCode = nextStatus ?? HttpStatus.ok
          ..headers.contentType = ContentType.json;
        if (nextBody != null) {
          response.write(jsonEncode(nextBody));
        }
        await response.close();
      });
  }

  RemoteConfigFeatureFlagsSource sourceFor(
    HttpServer server, {
    Duration timeout = const Duration(seconds: 2),
  }) {
    final authority = '${server.address.host}:${server.port}';
    return RemoteConfigFeatureFlagsSource(
      baseUrl: Uri.http(authority, '/'),
      timeout: timeout,
      buildInfo: buildInfo,
    );
  }

  Object? payload(Map<String, Object?> flags) => <String, Object?>{
    'flags': flags,
    'versionPolicy': <String, Object?>{},
    'experiments': <String, Object?>{},
    'revision': '1',
  };

  Future<void> expectLoad(
    RemoteConfigFeatureFlagsSource source,
    FeatureFlags expected,
  ) async {
    expect(await source.load(), expected);
  }

  test('decodes typed booleans, string, and integer flags from the flags slice', () async {
    nextStatus = HttpStatus.ok;
    nextBody = payload(const <String, Object?>{
      'onboarding_revamp': true,
      'home_redesign': false,
      'checkout_v2': true,
      'profile_sync': true,
      'search_backend': 'algolia',
      'checkout_rollout_percent': 42,
    });
    await startServer();
    await expectLoad(
      sourceFor(server),
      FeatureFlags.fromSlice(const <String, Object?>{
        'onboarding_revamp': true,
        'checkout_v2': true,
        'profile_sync': true,
        'search_backend': 'algolia',
        'checkout_rollout_percent': 42,
      }),
    );
  });

  test('empty flags slice yields the defaults baseline', () async {
    nextStatus = HttpStatus.ok;
    nextBody = payload(const <String, Object?>{});
    await startServer();
    await expectLoad(sourceFor(server), const FeatureFlags.defaults());
  });

  test('missing flags slice yields the defaults baseline', () async {
    nextStatus = HttpStatus.ok;
    nextBody = const <String, Object?>{
      'versionPolicy': <String, Object?>{},
      'experiments': <String, Object?>{},
      'revision': '1',
    };
    await startServer();
    await expectLoad(sourceFor(server), const FeatureFlags.defaults());
  });

  test('non-200 degrades to defaults without faking an enabled flag', () async {
    nextStatus = HttpStatus.serviceUnavailable;
    nextBody = const <String, Object?>{'error': 'down'};
    await startServer();
    await expectLoad(sourceFor(server), const FeatureFlags.defaults());
  });

  test('malformed body degrades to defaults', () async {
    nextStatus = HttpStatus.ok;
    nextBody = 'not-json';
    await startServer();
    await expectLoad(sourceFor(server), const FeatureFlags.defaults());
  });

  test('unreachable host degrades honestly to defaults', () async {
    final source = RemoteConfigFeatureFlagsSource(
      baseUrl: Uri.http('127.0.0.1:1', '/'),
      timeout: const Duration(milliseconds: 50),
      buildInfo: buildInfo,
    );
    await expectLoad(source, const FeatureFlags.defaults());
  });

  test('load caches the last successful value for later degrade', () async {
    // First request: serve a populated flags slice.
    nextStatus = HttpStatus.ok;
    nextBody = payload(const <String, Object?>{'checkout_v2': true});
    await startServer();
    final source = sourceFor(server);
    await expectLoad(
      source,
      FeatureFlags.fromSlice(const <String, Object?>{'checkout_v2': true}),
    );

    // Second request: the server now fails. The source returns the cached
    // value rather than reverting to defaults or throwing.
    nextStatus = HttpStatus.internalServerError;
    await expectLoad(
      source,
      FeatureFlags.fromSlice(const <String, Object?>{'checkout_v2': true}),
    );
  });

  test('changes emits nothing (poll-backed source)', () async {
    nextStatus = HttpStatus.ok;
    nextBody = payload(const <String, Object?>{});
    await startServer();
    final source = sourceFor(server);
    expect(await source.changes().isEmpty, isTrue);
  });

  test('withClient reads through an injected RemoteConfigClient', () async {
    nextStatus = HttpStatus.ok;
    nextBody = payload(const <String, Object?>{'profile_sync': true});
    await startServer();
    final authority = '${server.address.host}:${server.port}';
    final source = RemoteConfigFeatureFlagsSource.withClient(
      RemoteConfigClient(baseUrl: Uri.http(authority, '/'), timeout: const Duration(seconds: 2)),
      buildInfo,
    );
    await expectLoad(
      source,
      FeatureFlags.fromSlice(const <String, Object?>{'profile_sync': true}),
    );
  });

  test('InMemoryFeatureFlagsSource is the no-backend peer (sanity)', () async {
    // Documents the C4 contract: three peer sources, one shared client. The
    // in-memory default needs no backend and returns the honest baseline.
    final inMemory = InMemoryFeatureFlagsSource();
    addTearDown(inMemory.dispose);
    expect(await inMemory.load(), const FeatureFlags.defaults());
  });
}
