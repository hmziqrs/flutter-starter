import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:starter/infrastructure/error_reporting/crash_reporter.dart';
import 'package:starter/infrastructure/error_reporting/flutter_error_forwarder.dart';
import 'package:starter/infrastructure/firebase/lazy_firebase_instance.dart';
import 'package:starter/infrastructure/firebase/reporting_supported.dart';
import 'package:starter/infrastructure/logging/log_redactor.dart';

final class FirebaseCrashlyticsCrashReporter with FlutterErrorForwarder implements CrashReporter {
  FirebaseCrashlyticsCrashReporter({
    required this.verbose,
    this.redactor = const LogRedactor(),
  });

  final bool verbose;
  final LogRedactor redactor;

  final LazyFirebaseInstance<FirebaseCrashlytics> _instance =
      LazyFirebaseInstance<FirebaseCrashlytics>(
        () async => FirebaseCrashlytics.instance,
      );

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    Map<String, Object?> context = const {},
  }) async {
    await _instance.runIfSupported((crashlytics) async {
      final report = CrashReport.fromError(
        error,
        stack,
        context: context,
        verbose: verbose,
        redactor: redactor,
      );
      await crashlytics.recordError(
        Exception(report.message),
        report.stack != null ? StackTrace.fromString(report.stack!) : null,
        reason: 'redacted_context',
        printDetails: false,
        information: report.context.entries.map((e) => '${e.key}=${e.value}'),
      );
    }, supported: firebaseCrashlyticsSupported);
  }
}
