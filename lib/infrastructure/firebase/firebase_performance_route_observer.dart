import 'dart:async';

import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/widgets.dart';
import 'package:starter/infrastructure/firebase/performance_supported.dart';
import 'package:starter/infrastructure/logging/app_logger.dart';

class FirebasePerformanceRouteObserver extends NavigatorObserver {
  FirebasePerformanceRouteObserver({AppLogger? logger}) : _logger = logger ?? AppLogger.bootstrap();

  final AppLogger _logger;

  final Map<String, Trace> _traces = <String, Trace>{};

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _startTrace(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) {
      _stopTrace(oldRoute);
    }
    if (newRoute != null) {
      _startTrace(newRoute);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stopTrace(route);
  }

  void _startTrace(Route<dynamic>? route) {
    if (!firebasePerformanceSupported || route == null) {
      return;
    }
    final name = _routeName(route);
    _stopTraceByName(name);
    try {
      final trace = FirebasePerformance.instance.newTrace('route:$name');
      unawaited(trace.start());
      _traces[name] = trace;
    } on Object catch (error, stackTrace) {
      _logger.warning('firebase_perf.route_trace.start', error: error, stackTrace: stackTrace);
    }
  }

  void _stopTrace(Route<dynamic>? route) {
    if (!firebasePerformanceSupported || route == null) {
      return;
    }
    _stopTraceByName(_routeName(route));
  }

  void _stopTraceByName(String name) {
    final trace = _traces.remove(name);
    if (trace == null) {
      return;
    }
    try {
      unawaited(trace.stop());
    } on Object catch (error, stackTrace) {
      _logger.warning('firebase_perf.route_trace.stop', error: error, stackTrace: stackTrace);
    }
  }

  String _routeName(Route<dynamic> route) {
    final name = route.settings.name;
    if (name != null && name.isNotEmpty) {
      return name;
    }
    return 'unknown';
  }
}
