import 'package:flutter/foundation.dart';

/// Whether Firebase Performance Monitoring has a working platform
/// implementation on the current host. `firebase_performance` has no
/// implementation for macOS, Linux, or Windows — calling it there throws
/// `MissingPluginException`, which would break the macOS golden test and the
/// Linux integration smoke flow.
bool get firebasePerformanceSupported =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.android;
