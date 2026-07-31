import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:starter/infrastructure/error_reporting/crash_reporter.dart';
import 'package:starter/infrastructure/logging/log_redactor.dart';

final class SentryCrashReporter implements CrashReporter {
  SentryCrashReporter({
    required this.verbose,
    this.redactor = const LogRedactor(),
  });

  final bool verbose;
  final LogRedactor redactor;

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    Map<String, Object?> context = const {},
  }) async {
    final report = CrashReport.fromError(
      error,
      stack,
      context: context,
      verbose: verbose,
      redactor: redactor,
    );
    try {
      await _capture(report);
    } on Object {
      // Never rethrow: must not break the error path it is observing.
    }
  }

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) {
    return recordError(
      details.exception,
      details.stack,
      context: <String, Object?>{'source': 'flutter_framework'},
    );
  }

  Future<void> _capture(CrashReport report) async {
    // captureException (not captureMessage) so Sentry applies crash-stream grouping.
    await Sentry.captureException(
      Exception(report.message),
      stackTrace: report.stack != null ? StackTrace.fromString(report.stack!) : null,
      withScope: (scope) async {
        await scope.setContexts('context', report.context);
      },
    );
  }
}
