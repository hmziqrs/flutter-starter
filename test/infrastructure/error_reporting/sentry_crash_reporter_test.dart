import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/infrastructure/error_reporting/crash_reporter.dart';
import 'package:starter/infrastructure/error_reporting/sentry_crash_reporter.dart';

void main() {
  group('SentryCrashReporter', () {
    test('is a CrashReporter', () {
      expect(SentryCrashReporter(verbose: false), isA<CrashReporter>());
    });

    test('recordError never rethrows when the SDK is unavailable', () async {
      final reporter = SentryCrashReporter(verbose: false);

      await expectLater(
        reporter.recordError(
          Exception('boom'),
          StackTrace.current,
          context: <String, Object?>{'request_id': 'request-1'},
        ),
        completes,
      );
    });

    test('recordFlutterError never rethrows when the SDK is unavailable', () async {
      final reporter = SentryCrashReporter(verbose: true);

      await expectLater(
        reporter.recordFlutterError(
          FlutterErrorDetails(exception: Exception('boom')),
        ),
        completes,
      );
    });
  });
}
