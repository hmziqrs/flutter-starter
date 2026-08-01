import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:starter/infrastructure/firebase/performance_supported.dart';

final class FirebasePerformanceDioInterceptor extends Interceptor {
  FirebasePerformanceDioInterceptor();

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
        // ignored
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
      // ignored
    }
  }

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
