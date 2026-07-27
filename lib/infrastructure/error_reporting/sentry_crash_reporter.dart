import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:starter/infrastructure/error_reporting/crash_reporter.dart';
import 'package:starter/infrastructure/logging/log_redactor.dart';

/// Optional remote [CrashReporter] backed by the Sentry SDK.
///
/// Constructed at the composition root only when a DSN is configured; the SDK
/// itself is initialized there (`SentryFlutter.init`) with that DSN. Every SDK
/// call is wrapped in `try/on Object` and any failure is dropped — a reporter
/// must never break the error path it observes. Only the redacted
/// [CrashReport] message is forwarded as error text; the stack trace is
/// attached (as structured context) only when [verbose] is true, so a
/// non-verbose build ships only the redacted message.
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
      // Never rethrow: crash reporting must not break the error path it is
      // observing. The report is dropped.
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
    await Sentry.captureMessage(
      report.message,
      level: SentryLevel.error,
      withScope: (scope) async {
        await scope.setContexts('context', report.context);
        if (report.stack case final stack?) {
          await scope.setContexts('stack_trace', stack);
        }
      },
    );
  }
}
