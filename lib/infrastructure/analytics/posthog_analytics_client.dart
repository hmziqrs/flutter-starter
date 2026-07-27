import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:starter/infrastructure/analytics/analytics_client.dart';
import 'package:starter/infrastructure/analytics/analytics_event.dart';
import 'package:starter/infrastructure/secure_storage/secure_store.dart';

/// Optional remote [AnalyticsClient] backed by the PostHog SDK.
///
/// Constructed at the composition root only when the consumer wires PostHog
/// credentials (the consumer runs `Posthog().init(...)` once in `bootstrap`
/// with those credentials); it is the single override seam for
/// [analyticsClientProvider]. Every SDK call is wrapped in `try/on Object` and
/// any failure is dropped — analytics must never break the UX it measures.
///
/// Opt-in gate (C4): every emit first reads the persisted [analyticsOptInKey]
/// from [secureStore]. When the user has not opted in (the stored value is
/// absent or not `'true'`), the event is dropped silently and PostHog is never
/// called — toggling opt-in off in Settings takes effect on the next emit. The
/// no-backend NoopAnalyticsClient default ignores this key (it drops everything
/// regardless). Treats a store read failure as "not opted in" so a keychain
/// error never leaks an unexpected event.
final class PosthogAnalyticsClient implements AnalyticsClient {
  PosthogAnalyticsClient({required this.secureStore});

  final SecureStore secureStore;

  @override
  Future<void> track(AnalyticsEvent event) async {
    if (!await _optedIn()) {
      return;
    }
    try {
      switch (event) {
        case ScreenView(:final routeName):
          await Posthog().screen(screenName: routeName);
        case Tap(:final target):
          await Posthog().capture(
            eventName: 'tap',
            properties: <String, Object>{'target': target},
          );
        case FunnelStep(:final name, :final step):
          await Posthog().capture(
            eventName: 'funnel_step',
            properties: <String, Object>{'name': name, 'step': step},
          );
      }
    } on Object {
      // Swallow: analytics must never break the UX it measures.
    }
  }

  @override
  Future<void> setUserProperty(UserProperty property) async {
    if (!await _optedIn()) {
      return;
    }
    try {
      await Posthog().setPersonProperties(
        userPropertiesToSet: <String, Object>{property.key: property.value},
      );
    } on Object {
      // Swallow; see [track].
    }
  }

  @override
  Future<void> setUserId(String? userId) async {
    if (!await _optedIn()) {
      return;
    }
    try {
      if (userId case final id?) {
        await Posthog().identify(userId: id);
      } else {
        await Posthog().reset();
      }
    } on Object {
      // Swallow; see [track].
    }
  }

  Future<bool> _optedIn() async {
    try {
      return await secureStore.read(analyticsOptInKey) == 'true';
    } on Object {
      // A keychain read failure degrades to "not opted in" rather than risking
      // an unexpected emit (C2: never fake consent).
      return false;
    }
  }
}
