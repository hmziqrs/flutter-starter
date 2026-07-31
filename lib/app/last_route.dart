import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/features/settings/settings_store.dart';

const String lastRouteKey = 'nav.last_route';

/// Returns null for routes that must never persist: splash (relaunch loop), gates, and dynamic OTP.
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

final class LastRouteObserver extends NavigatorObserver {
  // Backing field is private by convention, so the initializing-formal lint does not apply.
  // ignore: prefer_initializing_formals
  LastRouteObserver({required SettingsStore store}) : _store = store;

  final SettingsStore _store;

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
    // catchError keeps a write failure out of the zone's uncaught-error handler.
    unawaited(_store.writeString(lastRouteKey, path).catchError((Object _, StackTrace _) {}));
  }
}
