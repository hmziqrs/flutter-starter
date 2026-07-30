import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:starter/infrastructure/analytics/analytics_client.dart';
import 'package:starter/infrastructure/analytics/analytics_event.dart';
import 'package:starter/infrastructure/firebase/reporting_supported.dart';

/// Optional remote [AnalyticsClient] backed by the Firebase Analytics (GA4)
/// SDK. Runs alongside the existing analytics backend (PostHog / Noop) via a
/// composite fan-out; constructed unconditionally and self-disables on
/// unsupported hosts ([firebaseAnalyticsSupported] is `false` on Linux /
/// Windows) and when Firebase was never initialized. Every SDK call is
/// wrapped in `try/on Object` and any failure is dropped.
///
/// Unlike PosthogAnalyticsClient, this adapter does not consult
/// `analyticsOptInKey` itself: the GA4 collection toggle is owned by the
/// Firebase console / `setAnalyticsCollectionEnabled`.
final class FirebaseAnalyticsClient implements AnalyticsClient {
  FirebaseAnalyticsClient();

  /// Lazily-resolved SDK instance. `FirebaseAnalytics.instance` throws
  /// `[core/no-app]` when Firebase hasn't been initialized.
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
      // Firebase not initialized or plugin missing; mark unresolvable so we
      // don't retry the failing lookup on every event.
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
      // GA4 validates the property name (1-24 alphanumeric, leading alpha)
      // and throws on violation; swallowed so an out-of-rules key never
      // breaks the emit path (PostHog still receives it via the composite).
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
      // A null id clears the GA4 user id, mirroring PostHog's reset() branch.
      await analytics.setUserId(id: userId);
    } on Object {
      // Swallow; see [track].
    }
  }
}
