import 'package:flutter/foundation.dart';

/// Whether Firebase Analytics has a working platform implementation on the
/// current host.
///
/// `firebase_analytics` ships native implementations for Android, iOS, and
/// macOS plus an endorsed web implementation (`firebase_analytics_web`). It has
/// **no** implementation for Linux or Windows (the Windows target is a stub that
/// throws `MissingPluginException`). This is a wider surface than
/// `firebasePerformanceSupported` (which excludes macOS / web) — Analytics
/// genuinely works on macOS and web.
///
/// Every Firebase Analytics call site (the FirebaseAnalyticsClient adapter)
/// early-returns when this is `false`, and additionally wraps the Firebase
/// invocation in `try / on Object` so a runtime gap — e.g. Firebase not yet
/// initialized in a no-backend build (`[core/no-app]`) — never propagates into
/// the host call path. Mirrors the `firebasePerformanceSupported` discipline.
bool get firebaseAnalyticsSupported =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.macOS;

/// Whether Firebase Crashlytics has a working platform implementation on the
/// current host.
///
/// `firebase_crashlytics` ships native implementations for Android, iOS, and
/// macOS only. There is **no** web implementation (Crashlytics does not run on
/// web), and Linux / Windows are unsupported. Calling the plugin on an
/// unsupported host throws `MissingPluginException`.
///
/// Every Firebase Crashlytics call site (the FirebaseCrashlyticsCrashReporter
/// adapter) early-returns when this is `false`, and additionally wraps the
/// Firebase invocation in `try / on Object` so a runtime gap — e.g. Firebase
/// not yet initialized in a no-backend build (`[core/no-app]`) — never breaks
/// the error path it observes. Mirrors the `firebasePerformanceSupported`
/// discipline.
bool get firebaseCrashlyticsSupported =>
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.macOS;
