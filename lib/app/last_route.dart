import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/features/settings/settings_store.dart';

/// Settings key persisting the last-observed route location so a relaunched
/// app can return the user to where they left off. Always a resolvable path
/// string (e.g. `/auth/login`), never a route name.
const String lastRouteKey = 'nav.last_route';

/// Maps a go_router route name (`route.settings.name`) to the path string
/// persisted under [lastRouteKey]. Returns `null` for routes that must never
/// be persisted: splash (would loop relaunch back into splash), dev-only
/// gallery/diagnostics routes, redirect-normalized settings sub-routes, OTP
/// (dynamic `:purpose`), and the gate routes (force-update/biometric-lock,
/// re-evaluated by the redirect on every launch anyway).
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
      return null;
  }
}

/// A [NavigatorObserver] that persists the latest restorable route path to
/// [SettingsStore] under [lastRouteKey]. Writes are fire-and-forget and never
/// throw; a persistence failure only means the next cold start lands on the
/// default initial location. The saved path is intentionally weaker than the
/// redirect chain, which re-evaluates update/onboarding/session/biometric
/// gates after `initialLocation` is set.
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
    // catchError keeps a write failure inside the Future chain so it never
    // reaches the zone's uncaught-error handler or blocks navigation.
    unawaited(_store.writeString(lastRouteKey, path).catchError((Object _, StackTrace _) {}));
  }
}
