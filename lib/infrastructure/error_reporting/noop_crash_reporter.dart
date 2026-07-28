import 'package:flutter/foundation.dart';
import 'package:starter/infrastructure/error_reporting/crash_reporter.dart';

/// Production default [CrashReporter].
///
/// Runs green with zero backend: it records nothing remotely and never throws.
/// The local application logger has already logged the error before this sink
/// is reached, so discarding here is honest — crash ingest has no user-facing
/// success state to fake.
final class NoopCrashReporter implements CrashReporter {
  const NoopCrashReporter();

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    Map<String, Object?> context = const {},
  }) async {
    // Intentional no-op: the local application logger is the source of truth
    // when no remote aggregator is configured. Never fakes an upload.
  }

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) async {
    // Intentional no-op; see [recordError].
  }
}
