import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:starter/infrastructure/analytics/analytics_client.dart';
import 'package:starter/infrastructure/analytics/analytics_event.dart';
import 'package:starter/infrastructure/firebase/reporting_supported.dart';

/// Optional remote [AnalyticsClient] backed by the Firebase Analytics (GA4)
/// SDK.
///
/// Runs **alongside** the existing analytics backend (PostHog / Noop) via a
/// composite fan-out at the composition root — it is constructed unconditionally
/// and self-disables on unsupported hosts ([firebaseAnalyticsSupported] is
/// `false` on Linux / Windows). The SDK itself (`Firebase.initializeApp`) is
/// initialized by the consumer; in a no-backend mobile build Firebase is never
/// initialized and every call degrades to a swallowed `[core/no-app]`, identical
/// to the `firebase_performance` adapters. Every SDK call is wrapped in
/// `try/on Object` and any failure is dropped — analytics must never break the
/// UX it measures. Mirrors PosthogAnalyticsClient's swallow discipline.
///
/// Unlike PosthogAnalyticsClient, this adapter does NOT consult the
/// `analyticsOptInKey` opt-in gate itself: the GA4 collection toggle is owned by
/// the Firebase console / `setAnalyticsCollectionEnabled`, and the composite
/// already routes the same events to PostHog which applies its own opt-in. The
/// typed [AnalyticsEvent] sealed hierarchy is translated to the GA4 payload
/// shape here (the single translation seam), never on the public surface.
final class FirebaseAnalyticsClient implements AnalyticsClient {
  FirebaseAnalyticsClient();

  /// Lazily-resolved SDK instance. Resolving [FirebaseAnalytics.instance] calls
  /// `Firebase.app()`, which throws `[core/no-app]` when Firebase has not been
  /// initialized — so resolution itself is guarded and never throws.
  FirebaseAnalytics? _analytics;
  bool _resolveFailed = false;

  Future<FirebaseAnalytics?> _resolve() async {
    if (_analytics != null) {
      return _analytics;
    }
    if (_resolveFailed) {
      return null;
    }
    try {
      return _analytics = FirebaseAnalytics.instance;
    } on Object {
      // Firebase not initialized ([core/no-app]) or the plugin is missing on
      // this host. Mark unresolvable so subsequent emits short-circuit cheaply
      // rather than re-attempting the failing lookup on every event.
      _resolveFailed = true;
      return null;
    }
  }

  @override
  Future<void> track(AnalyticsEvent event) async {
    if (!firebaseAnalyticsSupported) {
      return;
    }
    final analytics = await _resolve();
    if (analytics == null) {
      return;
    }
    try {
      switch (event) {
        case ScreenView(:final routeName):
          await analytics.logScreenView(screenName: routeName);
        case Tap(:final target):
          await analytics.logEvent(
            name: 'tap',
            parameters: <String, Object>{'target': target},
          );
        case FunnelStep(:final name, :final step):
          await analytics.logEvent(
            name: 'funnel_step',
            parameters: <String, Object>{'name': name, 'step': step},
          );
      }
    } on Object {
      // Swallow: analytics must never break the UX it measures.
    }
  }

  @override
  Future<void> setUserProperty(UserProperty property) async {
    if (!firebaseAnalyticsSupported) {
      return;
    }
    final analytics = await _resolve();
    if (analytics == null) {
      return;
    }
    try {
      // setUserProperty validates the property name (1–24 alphanumeric, leading
      // alpha) and throws ArgumentError on a violation — swallowed here so a
      // product-defined key that falls outside GA4's rules never breaks the
      // emit path (the PostHog arm still receives it via the composite).
      await analytics.setUserProperty(name: property.key, value: property.value);
    } on Object {
      // Swallow; see [track].
    }
  }

  @override
  Future<void> setUserId(String? userId) async {
    if (!firebaseAnalyticsSupported) {
      return;
    }
    final analytics = await _resolve();
    if (analytics == null) {
      return;
    }
    try {
      // A null id clears the GA4 user id (dissociation), mirroring PostHog's
      // reset() branch.
      await analytics.setUserId(id: userId);
    } on Object {
      // Swallow; see [track].
    }
  }
}
