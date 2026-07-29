import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:starter/infrastructure/firebase/performance_supported.dart';

/// A Dio [Interceptor] that reports every HTTP round-trip to Firebase
/// Performance Monitoring as an [HttpMetric].
///
/// On [onRequest] an [HttpMetric] is created for the request URI + method and
/// started; on [onResponse] / [onError] the response code (+ payload size and
/// content type when available) is recorded and the metric is stopped. The
/// in-flight metric is associated with its [RequestOptions] via an [Expando] so
/// the response/error handlers can find it without mutating the request's
/// `extra` map (which the optional dev inspector may serialize).
///
/// The interceptor is **always safe to attach**: on unsupported hosts
/// ([firebasePerformanceSupported] is `false` — macOS / Linux / Windows) every
/// handler is a no-op, and each Firebase call is wrapped in `try / on Object`
/// so a runtime gap (missing plugin, or Firebase not yet initialized in a
/// no-backend mobile build) never propagates into the HTTP path. It does not
/// alter [BaseOptions.validateStatus], error mapping, or any other interceptor.
final class FirebasePerformanceDioInterceptor extends Interceptor {
  /// Constructs a no-op-safe Firebase Performance Dio interceptor.
  ///
  /// Construction itself touches no Firebase state; the platform gate is
  /// evaluated per-handler.
  FirebasePerformanceDioInterceptor();

  /// In-flight metrics keyed by the identity of their [RequestOptions]. Cleared
  /// (set to `null`) on the first of [onResponse] / [onError] to fire.
  final Expando<HttpMetric> _metrics = Expando<HttpMetric>();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (firebasePerformanceSupported) {
      try {
        final metric = FirebasePerformance.instance.newHttpMetric(
          options.uri.toString(),
          _httpMethod(options.method),
        );
        // Fire-and-forget: accurate sub-millisecond timing is not relevant for
        // network metrics; the platform side sequences start/stop in order.
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
        // A transport failure (connection refused, timeout, ...) carries no
        // response; the metric is stopped without a response code in that case.
        _stop(metric, response: err.response);
      }
    }
    handler.next(err);
  }

  /// Records the response metadata (when present) and stops [metric]. Every
  /// Firebase call is defensive so a platform gap never reaches the caller.
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

  /// Best-effort response payload size in bytes. Prefers the `Content-Length`
  /// header (the on-the-wire measure); falls back to the decoded body length
  /// only when it is already a byte list (no allocation). Returns `null` when
  /// no size can be determined cheaply.
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

  /// Maps a Dio HTTP method string to the [HttpMethod] enum. Falls back to
  /// [HttpMethod.Get] for an unrecognized verb so a metric is always emitted.
  HttpMethod _httpMethod(String method) {
    switch (method.toUpperCase()) {
      case 'POST':
        return HttpMethod.Post;
      case 'PUT':
        return HttpMethod.Put;
      case 'DELETE':
        return HttpMethod.Delete;
      case 'PATCH':
        return HttpMethod.Patch;
      case 'HEAD':
        return HttpMethod.Head;
      case 'OPTIONS':
        return HttpMethod.Options;
      case 'CONNECT':
        return HttpMethod.Connect;
      case 'TRACE':
        return HttpMethod.Trace;
      case 'GET':
      default:
        return HttpMethod.Get;
    }
  }
}
