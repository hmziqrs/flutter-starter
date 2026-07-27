import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/infrastructure/error_reporting/crash_reporter.dart';
import 'package:starter/infrastructure/logging/log_redactor.dart';

void main() {
  group('CrashReport', () {
    test('redacts sensitive material from the error message', () {
      final report = CrashReport.fromError(
        Exception('Authorization: Bearer abc.def token=secret password=hunter2'),
        null,
        verbose: false,
      );

      expect(report.message, isNot(contains('abc.def')));
      expect(report.message, isNot(contains('secret')));
      expect(report.message, isNot(contains('hunter2')));
      expect(report.message, contains(LogRedactor.replacement));
    });

    test('forwards the stack trace only when verbose', () {
      final stack = StackTrace.current;

      final verbose = CrashReport.fromError(
        Exception('boom'),
        stack,
        verbose: true,
      );
      final quiet = CrashReport.fromError(
        Exception('boom'),
        stack,
        verbose: false,
      );

      expect(verbose.stack, stack.toString());
      expect(quiet.stack, isNull);
    });

    test('omits the stack trace when it is null even in verbose mode', () {
      final report = CrashReport.fromError(
        Exception('boom'),
        null,
        verbose: true,
      );

      expect(report.stack, isNull);
    });

    test('redacts structured context while preserving safe keys', () {
      final report = CrashReport.fromError(
        Exception('boom'),
        null,
        context: const <String, Object?>{
          'access_token': 'top-secret',
          'request_id': 'request-1',
        },
        verbose: false,
      );

      expect(report.context['access_token'], LogRedactor.replacement);
      expect(report.context['request_id'], 'request-1');
    });

    test('exposes an unmodifiable context map', () {
      final report = CrashReport.fromError(
        Exception('boom'),
        null,
        verbose: false,
      );

      expect(
        () => report.context['injected'] = 'value',
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('falls back to the runtime type when toString throws', () {
      const error = _ThrowingToStringError();
      final report = CrashReport.fromError(error, null, verbose: false);

      expect(report.message, error.runtimeType.toString());
    });

    test('builds redacted reports from FlutterErrorDetails', () {
      final details = FlutterErrorDetails(
        exception: Exception('password=hunter2'),
        stack: StackTrace.current,
      );

      final report = CrashReport.fromError(
        details.exception,
        details.stack,
        verbose: false,
      );

      expect(report.message, isNot(contains('hunter2')));
    });
  });

  group('CrashReporterBackend', () {
    test('noop and remote backends carry distinct values', () {
      const noop = NoopCrashReporterBackend();
      const remote = RemoteCrashReporterBackend(host: 'sentry.example.com');

      expect(noop, isA<NoopCrashReporterBackend>());
      expect(remote.host, 'sentry.example.com');
    });
  });
}

class _ThrowingToStringError implements Exception {
  const _ThrowingToStringError();

  @override
  String toString() => throw StateError('toString failed');
}
