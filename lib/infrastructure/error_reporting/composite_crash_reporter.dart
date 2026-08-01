import 'package:flutter/foundation.dart';
import 'package:starter/infrastructure/error_reporting/crash_reporter.dart';

final class CompositeCrashReporter implements CrashReporter {
  CompositeCrashReporter(List<CrashReporter> reporters)
    : _reporters = List<CrashReporter>.unmodifiable(reporters);

  final List<CrashReporter> _reporters;

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    Map<String, Object?> context = const {},
  }) => _fanOut((r) => r.recordError(error, stack, context: context));

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) =>
      _fanOut((r) => r.recordFlutterError(details));

  Future<void> _fanOut(Future<void> Function(CrashReporter reporter) call) async {
    for (final reporter in _reporters) {
      try {
        await call(reporter);
      } on Object {
        // ignored
      }
    }
  }
}
