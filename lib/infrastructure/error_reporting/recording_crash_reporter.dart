import 'package:starter/infrastructure/error_reporting/crash_reporter.dart';
import 'package:starter/infrastructure/error_reporting/flutter_error_forwarder.dart';
import 'package:starter/infrastructure/logging/log_redactor.dart';

final class RecordingCrashReporter with FlutterErrorForwarder implements CrashReporter {
  RecordingCrashReporter({
    required this.verbose,
    this.redactor = const LogRedactor(),
  });

  final bool verbose;
  final LogRedactor redactor;
  final List<CrashReport> _reports = [];

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
}
