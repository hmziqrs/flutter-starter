import 'package:flutter/foundation.dart';
import 'package:starter/infrastructure/error_reporting/crash_reporter.dart';
import 'package:starter/infrastructure/logging/log_redactor.dart';

/// List-backed [CrashReporter] for unit tests. Exercises the real
/// [CrashReport] redaction path and exposes captured reports for assertions.
final class RecordingCrashReporter implements CrashReporter {
  RecordingCrashReporter({
    required this.verbose,
    this.redactor = const LogRedactor(),
  });

  final bool verbose;
  final LogRedactor redactor;
  final List<CrashReport> _reports = [];

  /// Unmodifiable view of the captured reports, in insertion order.
  List<CrashReport> get reports => List<CrashReport>.unmodifiable(_reports);

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    Map<String, Object?> context = const {},
  }) async {
    _reports.add(
      CrashReport.fromError(
        error,
        stack,
        context: context,
        verbose: verbose,
        redactor: redactor,
      ),
    );
  }

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) {
    return recordError(
      details.exception,
      details.stack,
      context: <String, Object?>{'source': 'flutter_framework'},
    );
  }
}
