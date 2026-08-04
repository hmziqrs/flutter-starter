import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:starter/infrastructure/error_reporting/crash_reporter.dart';
import 'package:starter/infrastructure/error_reporting/flutter_error_forwarder.dart';
import 'package:starter/infrastructure/logging/log_redactor.dart';

final class SentryCrashReporter with FlutterErrorForwarder implements CrashReporter {
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
      // ignored
    }
  }

  Future<void> _capture(CrashReport report) async {
    await Sentry.captureException(
      Exception(report.message),
      stackTrace: report.stack != null ? StackTrace.fromString(report.stack!) : null,
      withScope: (scope) async {
        await scope.setContexts('context', report.context);
      },
    );
  }
}
