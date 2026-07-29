import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:starter/infrastructure/error_reporting/crash_reporter.dart';
import 'package:starter/infrastructure/firebase/reporting_supported.dart';
import 'package:starter/infrastructure/logging/log_redactor.dart';

/// Optional remote [CrashReporter] backed by the Firebase Crashlytics SDK.
///
/// Runs **alongside** the existing crash backend (Sentry / Noop) via a composite
/// fan-out at the composition root — it is constructed unconditionally and
/// self-disables on unsupported hosts ([firebaseCrashlyticsSupported] is `false`
/// on web / Linux / Windows). The SDK itself (`Firebase.initializeApp`) is
/// initialized by the consumer; in a no-backend mobile build Firebase is never
/// initialized and every call degrades to a swallowed `[core/no-app]`, identical
/// to the `firebase_performance` adapters.
///
/// Mirrors SentryCrashReporter's discipline exactly:
/// * Every SDK call is wrapped in `try/on Object` and never rethrown — a
///   reporter must never break the error path it observes.
/// * Only the redacted [CrashReport] leaves the device, built through the single
///   [CrashReport.fromError] choke point, so the SDK's own native-bit redaction
///   is not trusted to know the application's token formats. The stack trace is
///   forwarded only when [verbose] is `true`.
/// * [recordFlutterError] forwards to [recordError] rather than
///   `FirebaseCrashlytics.instance.recordFlutterError`, which would internally
///   re-present the error via `FlutterError.presentError` (double-handling) and
///   bypass the redaction choke point. The bootstrap `installErrorHandlers` is
///   the single owner of `FlutterError.onError`.
final class FirebaseCrashlyticsCrashReporter implements CrashReporter {
  FirebaseCrashlyticsCrashReporter({
    required this.verbose,
    this.redactor = const LogRedactor(),
  });

  final bool verbose;
  final LogRedactor redactor;

  /// Lazily-resolved SDK instance. Resolving [FirebaseCrashlytics.instance]
  /// calls `Firebase.app()`, which throws `[core/no-app]` when Firebase has not
  /// been initialized — so resolution itself is guarded and never throws.
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
      // Firebase not initialized ([core/no-app]) or the plugin is missing on
      // this host. Mark unresolvable so subsequent reports short-circuit
      // cheaply rather than re-attempting the failing lookup on every error.
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
    // Single redaction choke point: callers forward raw values; the producing
    // implementation scrubs them through CrashReport.fromError before any
    // network sink sees them.
    final report = CrashReport.fromError(
      error,
      stack,
      context: context,
      verbose: verbose,
      redactor: redactor,
    );
    try {
      await crashlytics.recordError(
        // The throwable's message is the already-redacted report text. Wrap in
        // an Exception so Crashlytics' native grouping/fingerprinting runs on
        // the redacted message (the core value of crash reporting), matching
        // SentryCrashReporter's pipeline.
        Exception(report.message),
        report.stack != null ? StackTrace.fromString(report.stack!) : null,
        reason: 'redacted_context',
        // `printDetails: false` suppresses Crashlytics' own noisy stderr print
        // of the (already-redacted) error; the local AppLogger is the source of
        // truth for dev visibility, wired in installErrorHandlers.
        printDetails: false,
        information: report.context.entries.map(
          (e) => '${e.key}=${e.value}',
        ),
      );
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
}
