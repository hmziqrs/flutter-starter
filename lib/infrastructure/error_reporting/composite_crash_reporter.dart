import 'package:flutter/foundation.dart';
import 'package:starter/infrastructure/error_reporting/crash_reporter.dart';

/// [CrashReporter] that fans every call out to a list of backends in parallel.
///
/// Constructed at the composition root to dual-report crashes — e.g. Sentry (or
/// the no-backend default) **and** Firebase Crashlytics — so each backend
/// receives the same report without the other's failures blocking it. Each
/// delegate is invoked inside its own `try/on Object` so a throwing backend (or
/// a backend whose SDK is unavailable on the current host) never prevents the
/// remaining delegates from receiving the report. The contract that
/// [CrashReporter] methods never rethrow is therefore preserved: this composite
/// itself never throws for backend failures.
///
/// Delegates are invoked in insertion order and awaited sequentially. Crash
/// reporting is fire-and-forget from the error path, so the small serialization
/// cost is irrelevant; the sequential await guarantees one slow backend does not
/// starve a faster one of ordering guarantees within a single report.
final class CompositeCrashReporter implements CrashReporter {
  CompositeCrashReporter(List<CrashReporter> reporters)
    : _reporters = List<CrashReporter>.unmodifiable(reporters);

  final List<CrashReporter> _reporters;

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    Map<String, Object?> context = const {},
  }) async {
    for (final reporter in _reporters) {
      try {
        await reporter.recordError(error, stack, context: context);
      } on Object {
        // A single backend failure must never block the remaining backends —
        // and must never break the error path it is observing.
      }
    }
  }

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) async {
    for (final reporter in _reporters) {
      try {
        await reporter.recordFlutterError(details);
      } on Object {
        // A single backend failure must never block the remaining backends —
        // and must never break the error path it is observing.
      }
    }
  }
}
