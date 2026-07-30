import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:starter/infrastructure/firebase/performance_supported.dart';

/// A Dio [Interceptor] that reports every HTTP round-trip to Firebase
/// Performance Monitoring as an [HttpMetric].
///
/// On [onRequest] an [HttpMetric] is created and started; on [onResponse] /
/// [onError] the response code (+ payload size / content type when
/// available) is recorded and the metric is stopped. The in-flight metric is
/// associated with its [RequestOptions] via an [Expando] rather than the
/// request's `extra` map (which the dev inspector may serialize).
///
/// Always safe to attach: on unsupported hosts ([firebasePerformanceSupported]
/// is `false` on macOS / Linux / Windows) every handler is a no-op, and each
/// Firebase call is wrapped in `try/on Object`.
final class FirebasePerformanceDioInterceptor extends Interceptor {
  FirebasePerformanceDioInterceptor();

  /// In-flight metrics keyed by [RequestOptions] identity; cleared on the
  /// first of [onResponse] / [onError] to fire.
  final Expando<HttpMetric> _metrics = Expando<HttpMetric>();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (firebasePerformanceSupported) {
      try {
        final metric = FirebasePerformance.instance.newHttpMetric(
          options.uri.toString(),
          _httpMethod(options.method),
        );
        unawaited(metric.start());
        _metrics[options] = metric;
      } on Object {
        // Best-effort: never block the request on performance monitoring.
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    if (firebasePerformanceSupported) {
      final options = response.requestOptions;
      final metric = _metrics[options];
      if (metric != null) {
        _metrics[options] = null;
        _stop(metric, response: response);
      }
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (firebasePerformanceSupported) {
      final options = err.requestOptions;
      final metric = _metrics[options];
      if (metric != null) {
        _metrics[options] = null;
        // A transport failure carries no response; stopped without a code.
        _stop(metric, response: err.response);
      }
    }
    handler.next(err);
  }

  void _stop(HttpMetric metric, {Response<dynamic>? response}) {
    try {
      if (response != null) {
        final statusCode = response.statusCode;
        if (statusCode != null) {
          metric.httpResponseCode = statusCode;
        }
        final contentType = response.headers.value(Headers.contentTypeHeader);
        if (contentType != null) {
          metric.responseContentType = contentType;
        }
        final size = _responsePayloadSize(response);
        if (size != null) {
          metric.responsePayloadSize = size;
        }
      }
      unawaited(metric.stop());
    } on Object {
      // Best-effort: never propagate a monitoring failure into Dio's flow.
    }
  }

  /// Prefers `Content-Length`; falls back to the decoded body length only
  /// when already a byte list (no allocation).
  int? _responsePayloadSize(Response<dynamic> response) {
    final contentLength = response.headers.value(Headers.contentLengthHeader);
    if (contentLength != null) {
      final parsed = int.tryParse(contentLength);
      if (parsed != null) {
        return parsed;
      }
    }
    final data = response.data;
    if (data is List<int>) {
      return data.length;
    }
    return null;
  }

  /// Maps a Dio HTTP method string to [HttpMethod], defaulting to `Get` for
  /// an unrecognized verb.
  HttpMethod _httpMethod(String method) => switch (method.toUpperCase()) {
    'POST' => HttpMethod.Post,
    'PUT' => HttpMethod.Put,
    'DELETE' => HttpMethod.Delete,
    'PATCH' => HttpMethod.Patch,
    'HEAD' => HttpMethod.Head,
    'OPTIONS' => HttpMethod.Options,
    'CONNECT' => HttpMethod.Connect,
    'TRACE' => HttpMethod.Trace,
    _ => HttpMethod.Get,
  };
}
