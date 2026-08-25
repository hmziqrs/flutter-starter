import 'package:flutter/foundation.dart';
import 'package:starter/infrastructure/error_reporting/crash_reporter.dart';

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
