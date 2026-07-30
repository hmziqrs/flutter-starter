import 'package:flutter/foundation.dart';

/// Whether Firebase Analytics has a working platform implementation on the
/// current host. `firebase_analytics` supports Android, iOS, macOS, and web,
/// but not Linux or Windows (throws `MissingPluginException`).
bool get firebaseAnalyticsSupported =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.macOS;

/// Whether Firebase Crashlytics has a working platform implementation on the
/// current host. `firebase_crashlytics` supports Android, iOS, and macOS only
/// — no web, Linux, or Windows.
bool get firebaseCrashlyticsSupported =>
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.macOS;
