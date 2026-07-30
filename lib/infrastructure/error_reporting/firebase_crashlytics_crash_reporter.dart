import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:starter/infrastructure/error_reporting/crash_reporter.dart';
import 'package:starter/infrastructure/firebase/reporting_supported.dart';
import 'package:starter/infrastructure/logging/log_redactor.dart';

/// Optional remote [CrashReporter] backed by the Firebase Crashlytics SDK.
///
/// Runs alongside the existing crash backend (Sentry / Noop) via a composite
/// fan-out at the composition root. Constructed unconditionally; self-disables
/// on unsupported hosts ([firebaseCrashlyticsSupported] is `false` on web /
/// Linux / Windows) and when Firebase was never initialized.
///
/// Every SDK call is wrapped in `try/on Object` and never rethrown. Only the
/// redacted [CrashReport] leaves the device, built through the single
/// [CrashReport.fromError] choke point. [recordFlutterError] forwards to
/// [recordError] rather than `FirebaseCrashlytics.instance.recordFlutterError`,
/// which would double-present the error via `FlutterError.presentError` and
/// bypass redaction.
final class FirebaseCrashlyticsCrashReporter implements CrashReporter {
  FirebaseCrashlyticsCrashReporter({
    required this.verbose,
    this.redactor = const LogRedactor(),
  });

  final bool verbose;
  final LogRedactor redactor;

  /// Lazily-resolved SDK instance. `FirebaseCrashlytics.instance` throws
  /// `[core/no-app]` when Firebase hasn't been initialized, so resolution is
  /// guarded and never throws.
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
      // Firebase not initialized ([core/no-app]) or plugin missing on this
      // host; mark unresolvable so we don't retry the failing lookup.
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
        // Wrapped in Exception so Crashlytics' grouping/fingerprinting runs
        // on the already-redacted message.
        Exception(report.message),
        report.stack != null ? StackTrace.fromString(report.stack!) : null,
        reason: 'redacted_context',
        // Suppresses Crashlytics' own stderr print; AppLogger is the dev
        // visibility source of truth.
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
