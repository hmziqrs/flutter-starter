import 'package:dio/dio.dart';
import 'package:starter/infrastructure/error_reporting/crash_reporter.dart';
import 'package:starter/infrastructure/error_reporting/flutter_error_forwarder.dart';
import 'package:starter/infrastructure/http/app_dio.dart';
import 'package:starter/infrastructure/logging/log_redactor.dart';

/// [CrashReporter] that POSTs redacted reports to `POST /v1/crashes` (contract
/// C3). Constructed in `AppDependencies.production` only when `AppConfig`
/// carries a `backendBaseUrl`; never throws — a reporter that rethrows inside
/// `PlatformDispatcher.onError` can loop (see crash-reporting.md risks).
///
/// Crash POSTs are fire-and-forget from the error handlers, so the reporter
/// owns a tightly timed transport (the same shape as the cache data source)
/// instead of riding the shared untimed app dio: an unresponsive backend must
/// not pin the request. An injected `dio` stays a verbatim test seam.
final class HttpCrashReporter with FlutterErrorForwarder implements CrashReporter {
  HttpCrashReporter({
    required Uri baseUrl,
    required this.platform,
    required this.appVersion,
    required this.verbose,
    this.redactor = const LogRedactor(),
    this.timeout = _timeout,
    Dio? dio,
  }) : _dio = dio ?? buildAppDio(baseUrl) {
    if (dio == null) {
      _dio.options
        ..connectTimeout = timeout
        ..sendTimeout = timeout
        ..receiveTimeout = timeout;
    }
  }

  static const Duration _timeout = Duration(seconds: 10);

  final bool verbose;
  final String platform;
  final String appVersion;
  final LogRedactor redactor;
  final Duration timeout;
  final Dio _dio;

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    Map<String, Object?> context = const {},
  }) async {
    final report = CrashReport.fromError(
      error,
      stack,
      context: context,
      verbose: verbose,
      redactor: redactor,
    );
    try {
      await _dio.post<Object?>(
        '/v1/crashes',
        data: <String, Object?>{
          'message': report.message,
          'stack': ?report.stack,
          'context': report.context,
          'platform': platform,
          'appVersion': appVersion,
        },
      );
    } on Object {}
  }
}
