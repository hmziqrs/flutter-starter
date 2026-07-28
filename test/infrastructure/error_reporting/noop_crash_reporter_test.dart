import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/infrastructure/error_reporting/crash_reporter.dart';
import 'package:starter/infrastructure/error_reporting/noop_crash_reporter.dart';

void main() {
  group('NoopCrashReporter', () {
    test('is a CrashReporter', () {
      expect(const NoopCrashReporter(), isA<CrashReporter>());
    });

    test('recordError completes without throwing', () async {
      const reporter = NoopCrashReporter();

      await expectLater(
        reporter.recordError(
          Exception('boom'),
          StackTrace.current,
          context: <String, Object?>{'token': 'secret'},
        ),
        completes,
      );
    });

    test('recordFlutterError completes without throwing', () async {
      const reporter = NoopCrashReporter();

      await expectLater(
        reporter.recordFlutterError(
          FlutterErrorDetails(exception: Exception('boom')),
        ),
        completes,
      );
    });

    test('never throws for pathological inputs', () async {
      const reporter = NoopCrashReporter();

      await expectLater(
        reporter.recordError(Object(), null),
        completes,
      );
      await expectLater(
        reporter.recordFlutterError(
          const FlutterErrorDetails(exception: Object()),
        ),
        completes,
      );
    });
  });
}
