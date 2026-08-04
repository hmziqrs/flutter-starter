import 'package:flutter/foundation.dart';
import 'package:starter/infrastructure/error_reporting/crash_reporter.dart';

/// Default `recordFlutterError` body that forwards to [CrashReporter.recordError]
/// tagged with `{'source': 'flutter_framework'}`.
///
/// Mixed into reporters whose forwarding implementation is byte-identical
/// (sentry, firebase_crashlytics, recording). Reporters whose body differs
/// (noop/composite) keep their own implementation.
///
/// The mixin `implements CrashReporter` (rather than `on CrashReporter`) so it
/// can be applied to the existing reporters, which declare
/// `implements CrashReporter` against the `interface class`. The interface
/// methods remain abstract within the mixin: `recordError` is supplied by the
/// concrete reporter and `recordFlutterError` is supplied here.
mixin FlutterErrorForwarder implements CrashReporter {
  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) {
    return recordError(
      details.exception,
      details.stack,
      context: <String, Object?>{'source': 'flutter_framework'},
    );
  }
}
