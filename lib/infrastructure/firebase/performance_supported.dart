import 'package:flutter/foundation.dart';

/// Whether Firebase Performance Monitoring has a working platform
/// implementation on the current host.
///
/// `firebase_performance` ships native implementations for Android and iOS and
/// a (no-op stub) web implementation. It has **no** implementation for macOS,
/// Linux, or Windows — calling the plugin on those hosts throws
/// `MissingPluginException`, which would break the macOS golden test and the
/// Linux integration smoke flow that exercise Dio HTTP + route navigation.
///
/// Every Firebase Performance call site (the Dio interceptor and the route
/// observer) early-returns when this is `false`, and additionally wraps the
/// Firebase invocation in `try / on Object` so a runtime gap — e.g. Firebase
/// not yet initialized in a no-backend mobile build (`[core/no-app]`) — never
/// propagates into the host call path.
bool get firebasePerformanceSupported =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.android;
