import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:starter/infrastructure/error_reporting/crash_reporter.dart';
import 'package:starter/infrastructure/firebase/reporting_supported.dart';
import 'package:starter/infrastructure/logging/log_redactor.dart';

/// Avoids FirebaseCrashlytics.recordFlutterError, which double-presents and skips redaction.
final class FirebaseCrashlyticsCrashReporter implements CrashReporter {
  FirebaseCrashlyticsCrashReporter({
    required this.verbose,
    this.redactor = const LogRedactor(),
  });

  final bool verbose;
  final LogRedactor redactor;

  FirebaseCrashlytics? _crashlytics;
  bool _resolveFailed = false;

  Future<FirebaseCrashlytics?> _resolve() async {
    if (_crashlytics != null) {
      return _crashlytics;
    }
    if (_resolveFailed) {
      return null;
    }
    try {
      return _crashlytics = FirebaseCrashlytics.instance;
    } on Object {
      _resolveFailed = true;
      return null;
    }
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    Map<String, Object?> context = const {},
  }) async {
    if (!firebaseCrashlyticsSupported) {
      return;
    }
    final crashlytics = await _resolve();
    if (crashlytics == null) {
      return;
    }
    final report = CrashReport.fromError(
      error,
      stack,
      context: context,
      verbose: verbose,
      redactor: redactor,
    );
    try {
      await crashlytics.recordError(
        Exception(report.message),
        report.stack != null ? StackTrace.fromString(report.stack!) : null,
        reason: 'redacted_context',
        printDetails: false,
        information: report.context.entries.map((e) => '${e.key}=${e.value}'),
      );
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
}
