import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/features/settings/settings_store.dart';

/// Settings key persisting the last-observed route location so a relaunched
/// app can return the user to where they left off (state-restoration spec).
///
/// The stored value is always a resolvable path string (e.g. `/auth/login`),
/// never a route name. Reuses the existing [SettingsStore] port (per-key, no
/// `clearAll`) — no new port, no network. Mirrors `SoftUpdateSnooze.key`.
const String lastRouteKey = 'nav.last_route';

/// Maps a go_router route name (as surfaced to a [NavigatorObserver] via
/// `route.settings.name`) to the path string persisted under [lastRouteKey].
///
/// go_router sets `Page.name = state.name ?? state.path`, and every route here
/// declares a name, so the observer always sees the NAME. We resolve it back
/// to a path at write time so the stored value is a real location bootstrap
/// can hand straight to `initialLocation`.
///
/// Returns `null` for routes that must never be persisted:
/// - [AppRoutes.splash] (cold-start screen; persisting it loops relaunch back
///   into splash),
/// - the dev-only gallery/diagnostics routes (gated by
///   `developmentToolsEnabled`; not restorable on a production launch),
/// - the redirect-normalized settings sub-routes (`appearance-settings`,
///   `language-settings` — the C5 redirect rewrites them to `/settings`),
/// - dynamic routes whose name does not round-trip to a single path
///   ([AppRoutes.otp] carries a `:purpose` parameter),
/// - the gate routes ([AppRoutes.forceUpdate], [AppRoutes.biometricLock]) —
///   the C5 redirect re-evaluates them on every launch, so persisting them
///   adds nothing.
String? pathForLastRouteName(String? name) {
  if (name == null) {
    return null;
  }
  switch (name) {
    case AppRoutes.home:
      return AppRoutes.homePath;
    case AppRoutes.pricing:
      return AppRoutes.pricingPath;
    case AppRoutes.settings:
      return AppRoutes.settingsPath;
    case AppRoutes.accessibilitySettings:
      return AppRoutes.accessibilitySettingsPath;
    case AppRoutes.aboutLicense:
      return AppRoutes.aboutLicensePath;
    case AppRoutes.login:
      return AppRoutes.loginPath;
    case AppRoutes.register:
      return AppRoutes.registerPath;
    case AppRoutes.forgotPassword:
      return AppRoutes.forgotPasswordPath;
    case AppRoutes.resetPassword:
      return AppRoutes.resetPasswordPath;
    case AppRoutes.updateProfile:
      return AppRoutes.updateProfilePath;
    case AppRoutes.onboarding:
      return AppRoutes.onboardingPath;
    case AppRoutes.onboardingPaywall:
      return AppRoutes.onboardingPaywallPath;
    default:
      // splash, dev routes, otp (dynamic), force-update / biometric-lock
      // (gates), appearance/language settings (redirect-normalized).
      return null;
  }
}

/// A [NavigatorObserver] that persists the latest restorable route path to
/// [SettingsStore] under [lastRouteKey] (state-restoration spec).
///
/// Attached to the `GoRouter` `observers` list at the composition root.
/// Writes are fire-and-forget and never throw — a persistence failure only
/// means the next cold start lands on the default initial location; navigation
/// is never blocked. Routes that do not resolve to a restorable path (see
/// [pathForLastRouteName]) are ignored, and consecutive identical writes are
/// deduped to avoid disk churn.
///
/// Last-route persistence is OPTIONAL and intentionally weaker than the C5
/// redirect chain: the saved path is handed to `initialLocation`, then
/// `_redirectSettingsDeepLinks` re-evaluates update / onboarding / session /
/// biometric gates, so a saved route never overrides a hard block or a fresh
/// install's onboarding.
final class LastRouteObserver extends NavigatorObserver {
  // Public parameter is named `store` for a clean call site; the backing field
  // is private by convention, so the initializing-formal lint does not apply.
  // ignore: prefer_initializing_formals
  LastRouteObserver({required SettingsStore store}) : _store = store;

  final SettingsStore _store;

  // Last path handed to the store; suppresses redundant consecutive writes.
  String? _lastWritten;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _persist(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) {
      _persist(newRoute);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) {
      _persist(previousRoute);
    }
  }

  void _persist(Route<dynamic> route) {
    final path = pathForLastRouteName(route.settings.name);
    if (path == null || path == _lastWritten) {
      return;
    }
    _lastWritten = path;
    // Fire-and-forget AND error-swallowing: the observer is synchronous and
    // must never block navigation or surface a persistence error. A failed
    // write degrades honestly to "no saved route" on the next cold start.
    // catchError keeps the error inside the Future chain so it never reaches
    // the zone's uncaught-error handler.
    unawaited(_store.writeString(lastRouteKey, path).catchError((Object _, StackTrace _) {}));
  }
}
