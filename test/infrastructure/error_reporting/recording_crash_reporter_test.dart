import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/infrastructure/error_reporting/crash_reporter.dart';
import 'package:starter/infrastructure/error_reporting/recording_crash_reporter.dart';
import 'package:starter/infrastructure/logging/log_redactor.dart';

void main() {
  group('RecordingCrashReporter', () {
    test('is a CrashReporter', () {
      expect(RecordingCrashReporter(verbose: false), isA<CrashReporter>());
    });

    test('captures and redacts a report', () async {
      final reporter = RecordingCrashReporter(verbose: true);

      await reporter.recordError(
        Exception('token=secret'),
        StackTrace.current,
        context: <String, Object?>{'request_id': 'request-1'},
      );

      expect(reporter.reports, hasLength(1));
      expect(reporter.reports.single.message, isNot(contains('secret')));
      expect(reporter.reports.single.stack, isNotNull);
      expect(reporter.reports.single.context['request_id'], 'request-1');
    });

    test('omits the stack when constructed non-verbose', () async {
      final reporter = RecordingCrashReporter(verbose: false);

      await reporter.recordError(Exception('boom'), StackTrace.current);

      expect(reporter.reports.single.stack, isNull);
    });

    test('recordFlutterError delegates to recordError with framework source', () async {
      final reporter = RecordingCrashReporter(verbose: false);

      await reporter.recordFlutterError(
        FlutterErrorDetails(exception: Exception('boom')),
      );

      expect(reporter.reports, hasLength(1));
      expect(reporter.reports.single.context['source'], 'flutter_framework');
    });

    test('records multiple reports in insertion order', () async {
      final reporter = RecordingCrashReporter(verbose: false);

      await reporter.recordError(Exception('first'), null);
      await reporter.recordError(Exception('second'), null);

      expect(reporter.reports.map((report) => report.message), [
        contains('first'),
        contains('second'),
      ]);
    });

    test('reports list is unmodifiable', () async {
      final reporter = RecordingCrashReporter(verbose: false);
      await reporter.recordError(Exception('boom'), null);

      expect(
        () => reporter.reports.add(
          CrashReport.fromError(Exception('x'), null, verbose: false),
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('redacts through the configured redactor', () async {
      final reporter = RecordingCrashReporter(verbose: false);

      await reporter.recordError(
        Exception('password=hunter2'),
        null,
        context: <String, Object?>{'access_token': 'top-secret'},
      );

      final report = reporter.reports.single;
      expect(report.message, isNot(contains('hunter2')));
      expect(report.context['access_token'], LogRedactor.replacement);
    });
  });
}
