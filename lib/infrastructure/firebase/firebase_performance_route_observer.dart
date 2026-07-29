import 'dart:async';

import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/widgets.dart';
import 'package:starter/infrastructure/firebase/performance_supported.dart';

/// A [NavigatorObserver] that records a Firebase Performance [Trace] per route.
///
/// On [didPush] a trace named `route:<name>` is started for the pushed route;
/// [didPop] stops the trace for the popped route (measuring how long the screen
/// was displayed); [didReplace] stops the trace for the outgoing route and
/// starts one for the incoming route. In-flight traces are keyed by route name;
/// starting a trace for a name that already has one first stops the previous
/// trace so no metric is ever leaked or double-counted.
///
/// The observer is **always safe to attach**: on unsupported hosts
/// ([firebasePerformanceSupported] is `false` — macOS / Linux / Windows) every
/// handler is a no-op, and each Firebase call is wrapped in `try / on Object`
/// so a runtime gap (missing plugin, or Firebase not yet initialized in a
/// no-backend mobile build) never throws into the navigator. It is added to the
/// router's observers unconditionally and self-disables on unsupported hosts.
class FirebasePerformanceRouteObserver extends NavigatorObserver {
  /// Constructs a no-op-safe Firebase Performance route observer.
  ///
  /// Construction itself touches no Firebase state; the platform gate is
  /// evaluated per-navigation-event.
  FirebasePerformanceRouteObserver();

  /// In-flight traces keyed by route name so [didPop] / [didReplace] can stop
  /// the matching trace.
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

  /// Starts a `route:<name>` trace for [route], first stopping any in-flight
  /// trace sharing that name. `null` [route] is a no-op.
  void _startTrace(Route<dynamic>? route) {
    if (!firebasePerformanceSupported || route == null) {
      return;
    }
    final name = _routeName(route);
    // Stop a lingering trace for the same name first so a re-push never leaks
    // the previous metric or double-counts.
    _stopTraceByName(name);
    try {
      final trace = FirebasePerformance.instance.newTrace('route:$name');
      // Fire-and-forget: the platform side sequences start/stop in order; the
      // trace measures wall-time until stop() regardless of awaiting.
      unawaited(trace.start());
      _traces[name] = trace;
    } on Object {
      // Best-effort: never block navigation on performance monitoring.
    }
  }

  /// Stops the in-flight trace for [route] (if any). No-op otherwise.
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
      // Best-effort: never propagate a monitoring failure into navigation.
    }
  }

  /// Resolves the trace name for [route]. Falls back to a generic `unknown`
  /// label when the route exposes no name (e.g. anonymous dialogs) so a trace
  /// is still emitted and the observer never throws.
  String _routeName(Route<dynamic> route) {
    final name = route.settings.name;
    if (name != null && name.isNotEmpty) {
      return name;
    }
    return 'unknown';
  }
}
