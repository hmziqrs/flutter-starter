import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/infrastructure/logging/log_redactor.dart';

sealed class CrashReporterBackend {
  const CrashReporterBackend();
}

final class NoopCrashReporterBackend extends CrashReporterBackend {
  const NoopCrashReporterBackend();
}

final class RemoteCrashReporterBackend extends CrashReporterBackend {
  const RemoteCrashReporterBackend({required this.host});

  final String host;
}

abstract interface class CrashReporter {
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    Map<String, Object?> context,
  });

  Future<void> recordFlutterError(FlutterErrorDetails details);
}

@immutable
final class CrashReport {
  const CrashReport({
    required this.message,
    required this.stack,
    required this.context,
  });

  factory CrashReport.fromError(
    Object error,
    StackTrace? stackTrace, {
    required bool verbose,
    Map<String, Object?> context = const {},
    LogRedactor redactor = const LogRedactor(),
  }) {
    return CrashReport(
      message: redactor.redactText(_stringify(error)),
      stack: verbose ? stackTrace?.toString() : null,
      context: Map<String, Object?>.unmodifiable(
        redactor.redactContext(context),
      ),
    );
  }

  final String message;

  final String? stack;

  final Map<String, Object?> context;

  static String _stringify(Object error) {
    try {
      return error.toString();
    } on Object {
      return error.runtimeType.toString();
    }
  }
}

final crashReporterProvider = Provider<CrashReporter>(
  (ref) => throw StateError('CrashReporter must be overridden at the composition root.'),
);

final crashReporterBackendProvider = Provider<CrashReporterBackend>(
  (ref) => const NoopCrashReporterBackend(),
);
