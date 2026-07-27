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
/// [CrashReport] message leaves the device, forwarded as the exception text via
/// Sentry's exception pipeline ([Sentry.captureException]) so reports land in
/// the crash stream with native stack-based grouping/fingerprinting. The stack
/// trace is forwarded through the same pipeline (enabling the native
/// stack-triage view) only when [verbose] is true, so a non-verbose build ships
/// only the redacted message. The SDK's own native-bit redaction is not trusted
/// — [CrashReport.fromError] is the single redaction choke point.
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
    // Route through Sentry's exception pipeline (not captureMessage) so the
    // report lands in the crash stream with stack-based grouping/fingerprinting
    // and the native stack-triage view — the core value of crash reporting.
    // The throwable's message is the already-redacted report text; the stack is
    // the verbose-gated, already-redacted report.stack. Only redacted text
    // leaves the device (the LogRedactor choke point in CrashReport.fromError).
    await Sentry.captureException(
      Exception(report.message),
      stackTrace: report.stack != null ? StackTrace.fromString(report.stack!) : null,
      withScope: (scope) async {
        await scope.setContexts('context', report.context);
      },
    );
  }
}
