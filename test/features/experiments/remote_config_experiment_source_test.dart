import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/experiments/deterministic_experiment_source.dart';
import 'package:starter/features/experiments/experiment_key.dart';
import 'package:starter/features/experiments/experiment_source.dart';
import 'package:starter/features/experiments/experiment_variant.dart';
import 'package:starter/features/settings/in_memory_settings_store.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';
import 'package:starter/infrastructure/remote_config/remote_config_experiment_source.dart';

void main() {
  const buildInfo = AppBuildInfo(version: '1.0.0', buildNumber: '1');

  late HttpServer server;

  tearDown(() async {
    await server.close(force: true);
  });

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

  RemoteConfigExperimentSource sourceFor(
    HttpServer server, {
    required DeterministicExperimentSource fallback,
    Duration timeout = const Duration(seconds: 2),
  }) {
    final authority = '${server.address.host}:${server.port}';
    return RemoteConfigExperimentSource(
      baseUrl: Uri.http(authority, '/'),
      timeout: timeout,
      buildInfo: buildInfo,
      fallback: fallback,
    );
  }

  DeterministicExperimentSource deterministic(InMemorySettingsStore store) =>
      DeterministicExperimentSource(store: store);

  Object? payload(Map<String, Object?> experiments) => <String, Object?>{
    'flags': <String, Object?>{},
    'versionPolicy': <String, Object?>{},
    'experiments': experiments,
    'revision': '1',
  };

  group('RemoteConfigExperimentSource', () {
    test('decodes variant, payload, and sticky from the experiments slice', () async {
      nextStatus = HttpStatus.ok;
      nextBody = payload(const <String, Object?>{
        'paywall_layout': <String, Object?>{
          'variant': 'treatment_a',
          'payload': <String, Object?>{'layout': 'compact'},
          'sticky': false,
        },
      });
      await startServer();
      final source = sourceFor(server, fallback: deterministic(InMemorySettingsStore()));

      final assignment = await source.assignmentFor(ExperimentKey.paywallLayout);
      expect(assignment.key, ExperimentKey.paywallLayout);
      expect(assignment.variant, isA<ExperimentVariantTreatmentA>());
      expect(assignment.variant.payload, const <String, Object?>{'layout': 'compact'});
      expect(assignment.sticky, isFalse);
      expect(assignment.source, ExperimentAssignmentSource.remote);
    });

    test('accepts lowerCamelCase variant names', () async {
      nextStatus = HttpStatus.ok;
      nextBody = payload(const <String, Object?>{
        'onboarding_cta': <String, Object?>{'variant': 'treatmentB'},
      });
      await startServer();
      final source = sourceFor(server, fallback: deterministic(InMemorySettingsStore()));
      final assignment = await source.assignmentFor(ExperimentKey.onboardingCta);
      expect(assignment.variant, const ExperimentVariantTreatmentB());
    });

    test('sticky defaults to true when the backend omits it', () async {
      nextStatus = HttpStatus.ok;
      nextBody = payload(const <String, Object?>{
        'paywall_layout': <String, Object?>{'variant': 'control'},
      });
      await startServer();
      final source = sourceFor(server, fallback: deterministic(InMemorySettingsStore()));
      final assignment = await source.assignmentFor(ExperimentKey.paywallLayout);
      expect(assignment.sticky, isTrue);
    });

    test('a missing entry degrades to the deterministic fallback', () async {
      nextStatus = HttpStatus.ok;
      nextBody = payload(const <String, Object?>{});
      await startServer();
      final store = InMemorySettingsStore();
      final fallback = deterministic(store);
      final source = sourceFor(server, fallback: fallback);

      final assignment = await source.assignmentFor(ExperimentKey.paywallLayout);
      expect(assignment.source, ExperimentAssignmentSource.local);
      expect(assignment.sticky, isTrue);
      expect(
        await store.readString(DeterministicExperimentSource.defaultStableIdKey),
        isNotNull,
      );
    });

    test('a malformed variant name degrades to the deterministic fallback', () async {
      nextStatus = HttpStatus.ok;
      nextBody = payload(const <String, Object?>{
        'paywall_layout': <String, Object?>{'variant': 'arm_unknown'},
      });
      await startServer();
      final source = sourceFor(server, fallback: deterministic(InMemorySettingsStore()));
      final assignment = await source.assignmentFor(ExperimentKey.paywallLayout);
      expect(assignment.source, ExperimentAssignmentSource.local);
    });

    test('a non-200 response degrades to the fallback without faking remote', () async {
      nextStatus = HttpStatus.serviceUnavailable;
      nextBody = const <String, Object?>{'error': 'down'};
      await startServer();
      final source = sourceFor(server, fallback: deterministic(InMemorySettingsStore()));
      final assignment = await source.assignmentFor(ExperimentKey.paywallLayout);
      expect(assignment.source, ExperimentAssignmentSource.local);
    });

    test('an unreachable host degrades honestly to the fallback', () async {
      final source = RemoteConfigExperimentSource(
        baseUrl: Uri.http('127.0.0.1:1', '/'),
        timeout: const Duration(milliseconds: 50),
        buildInfo: buildInfo,
        fallback: deterministic(InMemorySettingsStore()),
      );
      final assignment = await source.assignmentFor(ExperimentKey.paywallLayout);
      expect(assignment.source, ExperimentAssignmentSource.local);
    });

    test('changes emits nothing (poll-backed source)', () async {
      nextStatus = HttpStatus.ok;
      nextBody = payload(const <String, Object?>{});
      await startServer();
      final source = sourceFor(server, fallback: deterministic(InMemorySettingsStore()));
      expect(await source.changes().isEmpty, isTrue);
    });

    test('coalesces concurrent calls onto a single round-trip', () async {
      var requests = 0;
      final bound = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server = bound
        ..listen((request) async {
          requests++;
          final response = request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.json
            ..write(
              jsonEncode(
                payload(const <String, Object?>{
                  'paywall_layout': <String, Object?>{'variant': 'treatment_a'},
                  'onboarding_cta': <String, Object?>{'variant': 'control'},
                  'home_feed_order': <String, Object?>{'variant': 'treatment_b'},
                }),
              ),
            );
          await response.close();
        });
      addTearDown(() async => server.close(force: true));

      final authority = '${server.address.host}:${server.port}';
      final source = RemoteConfigExperimentSource(
        baseUrl: Uri.http(authority, '/'),
        timeout: const Duration(seconds: 2),
        buildInfo: buildInfo,
        fallback: deterministic(InMemorySettingsStore()),
      );

      final results = await Future.wait(
        <Future<ExperimentAssignment>>[
          for (final key in ExperimentKey.values) source.assignmentFor(key),
        ],
      );

      expect(results.length, ExperimentKey.values.length);
      expect(requests, 1);
    });

    test('DeterministicExperimentSource is the no-backend peer (sanity)', () async {
      final fallback = deterministic(InMemorySettingsStore());
      final assignment = await fallback.assignmentFor(ExperimentKey.paywallLayout);
      expect(assignment.source, ExperimentAssignmentSource.local);
    });
  });
}
