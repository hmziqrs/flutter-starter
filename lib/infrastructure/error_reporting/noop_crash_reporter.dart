import 'package:flutter/foundation.dart';
import 'package:starter/infrastructure/error_reporting/crash_reporter.dart';

/// Production default [CrashReporter]: records nothing remotely, never
/// throws. The local application logger has already logged the error before
/// this sink is reached.
final class NoopCrashReporter implements CrashReporter {
  const NoopCrashReporter();

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    Map<String, Object?> context = const {},
  }) async {}

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) async {}
}
