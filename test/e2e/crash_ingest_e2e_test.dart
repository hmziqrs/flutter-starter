import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/bootstrap.dart';
import 'package:starter/infrastructure/error_reporting/http_crash_reporter.dart';
import 'package:starter/infrastructure/http/app_dio.dart';
import 'package:starter/infrastructure/logging/app_logger.dart';

import '../infrastructure/hono_server_handle.dart';

/// Live crash-ingest e2e: a synthetic error flows through the real
/// `installErrorHandlers` seam into an [HttpCrashReporter] over the app dio.
void main() {
  final runtime = JsRuntime.resolve();

  group('crash ingest e2e (installErrorHandlers <-> live JS Hono)', () {
    if (runtime == null) {
      test(
        'skipped: no JS runtime (bun or npx tsx) available',
        () {},
        skip: 'no JS runtime (bun or npx tsx) available on PATH',
      );
      return;
    }

    HonoServerHandle? server;
    late final Uri baseUri;

    setUpAll(() async {
      final handle = await HonoServerHandle.start(runtime: runtime);
      server = handle;
      baseUri = handle.baseUri;
    });

    tearDownAll(() async {
      final handle = server;
      if (handle != null) {
        await handle.close();
      }
    });

    test('synthetic framework and platform errors are ingested and retained', () async {
      final reporter = HttpCrashReporter(
        baseUrl: baseUri,
        platform: 'e2e',
        appVersion: '1.0.0+1',
        verbose: true,
        dio: buildAppDio(baseUri),
      );
      installErrorHandlers(AppLogger(verbose: true), reporter);
      FlutterError.onError?.call(
        FlutterErrorDetails(exception: StateError('e2e flutter boom'), stack: StackTrace.current),
      );
      PlatformDispatcher.instance.onError?.call(
        StateError('e2e platform boom'),
        StackTrace.current,
      );

      final flutter = await _pollForCrash(baseUri, 'e2e flutter boom');
      expect(flutter?['stack'], isA<String>());
      expect(flutter?['context'], <String, Object?>{'source': 'flutter_framework'});
      expect(flutter?['platform'], 'e2e');
      expect(flutter?['appVersion'], '1.0.0+1');
      final platform = await _pollForCrash(baseUri, 'e2e platform boom');
      expect(platform?['message'], contains('e2e platform boom'));
      expect(platform?['context'], <String, Object?>{'source': 'platform'});
    });
  });
}

/// Polls `GET /v1/crashes/last` until a retained report matching [fragment]
/// arrives (the POST is fire-and-forget from the error handler), else null.
/// Mirrors the harness's `_healthOk`: a fresh client per poll, deadline-bounded.
Future<Map<String, Object?>?> _pollForCrash(Uri baseUri, String fragment) async {
  final deadline = DateTime.now().add(const Duration(seconds: 10));
  while (DateTime.now().isBefore(deadline)) {
    final client = HttpClient();
    try {
      final response = await (await client.getUrl(Uri.parse('$baseUri/v1/crashes/last'))).close();
      final decoded = response.statusCode == HttpStatus.ok
          ? jsonDecode(await utf8.decoder.bind(response).join())
          : null;
      final crashes = decoded is Map<String, Object?> ? decoded['crashes'] : null;
      for (final crash in crashes is List<Object?> ? crashes : const <Object?>[]) {
        if (crash is Map<String, Object?> && crash['message'] is String) {
          if ((crash['message']! as String).contains(fragment)) return crash;
        }
      }
    } on Object {
      // Not answering yet — retry until the deadline.
    } finally {
      client.close(force: true);
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  return null;
}
