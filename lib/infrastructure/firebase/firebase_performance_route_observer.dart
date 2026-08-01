import 'dart:async';

import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/widgets.dart';
import 'package:starter/infrastructure/firebase/performance_supported.dart';

class FirebasePerformanceRouteObserver extends NavigatorObserver {
  FirebasePerformanceRouteObserver();

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
    } on Object {
      // ignored
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
    } on Object {
      // ignored
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
