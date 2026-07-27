import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/infrastructure/logging/log_redactor.dart';

/// Read-only description of where a [CrashReporter] sends reports. Surfaced on
/// the development diagnostics page; never used to drive behavior.
sealed class CrashReporterBackend {
  const CrashReporterBackend();
}

/// No remote ingest is configured. Reports are discarded after the local
/// application logger has recorded them — the honest no-backend default.
final class NoopCrashReporterBackend extends CrashReporterBackend {
  const NoopCrashReporterBackend();
}

/// Reports are forwarded to a remote aggregator reachable at [host].
final class RemoteCrashReporterBackend extends CrashReporterBackend {
  const RemoteCrashReporterBackend({required this.host});

  final String host;
}

/// Captures unhandled Flutter framework errors and uncaught platform errors so
/// field failures can be triaged.
///
/// Implementations wrap their SDK in `try/on Object` and **never rethrow**: a
/// reporter that throws inside the platform error handler can loop the very
/// error it is observing. [recordError] is invoked fire-and-forget from the
/// error path, so it must remain total.
abstract interface class CrashReporter {
  /// Records [error] with its optional [stack] and structured [context].
  ///
  /// The redaction contract is owned by [CrashReport.fromError], the single
  /// choke point: callers forward raw values and the producing implementation
  /// scrubs them through [LogRedactor] before any network sink sees them.
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    Map<String, Object?> context,
  });

  /// Records a Flutter framework error reported through [FlutterError.onError].
  Future<void> recordFlutterError(FlutterErrorDetails details);
}

/// Redacted, immutable view of an error ready to forward to a crash aggregator.
///
/// [LogRedactor] scrubs the message and structured context here, and the stack
/// trace is included only when the producing [CrashReporter] was constructed
/// with verbose logging enabled — a non-verbose build ships only the redacted
/// message, because the SDK's own native-bit redaction is not trusted to know
/// the application's token formats. Never pre-redact elsewhere; this is the
/// single choke point.
@immutable
final class CrashReport {
  const CrashReport({
    required this.message,
    required this.stack,
    required this.context,
  });

  /// Builds a [CrashReport] from a raw [error], redacting the message and
  /// [context] through [redactor]. The [stack] trace is forwarded only when
  /// [verbose] is true.
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

  /// Redacted human-readable description of the error.
  final String message;

  /// Optional stack trace, present only when verbose logging is enabled.
  final String? stack;

  /// Structured, redacted, unmodifiable context attached to the report.
  final Map<String, Object?> context;

  static String _stringify(Object error) {
    try {
      return error.toString();
    } on Object {
      return error.runtimeType.toString();
    }
  }
}

/// Handwritten Riverpod handle for the [CrashReporter].
///
/// Overridden at the [ProviderScope] in `lib/app/app.dart`; the default throws
/// so a missing composition-root wiring fails loudly. The bootstrap error path
/// does **not** read this provider — it receives the reporter as a direct
/// parameter because it runs before the [ProviderScope] exists.
final crashReporterProvider = Provider<CrashReporter>(
  (ref) => throw StateError('CrashReporter must be overridden at the composition root.'),
);

/// Read-only backend descriptor for the diagnostics page. Defaults to the
/// no-backend [NoopCrashReporterBackend]; overridden at the [ProviderScope]
/// when a remote DSN is configured.
final crashReporterBackendProvider = Provider<CrashReporterBackend>(
  (ref) => const NoopCrashReporterBackend(),
);
