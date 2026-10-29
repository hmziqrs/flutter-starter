import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/features/settings/settings_store.dart';
import 'package:starter/infrastructure/logging/app_logger.dart';
import 'package:starter/shared/async/run_guarded.dart';

// ignore_for_file: prefer_initializing_formals, private fields with a default fallback

const String lastRouteKey = 'nav.last_route';

/// The single write-and-read allowlist: route names the observer may persist,
/// mapped to their cold-start restore paths.
///
/// Flow and gate routes — auth (`/auth/*`), onboarding, biometric lock,
/// passcode, force update, splash, dev-only screens — are deliberately
/// excluded: visiting one is transient, and persisting it would strand every
/// later cold start on a screen the user must complete or dismiss. The last
/// valid shell/content route stays the restore point instead.
const Map<String, String> _restorablePathsByRouteName = {
  AppRoutes.home: AppRoutes.homePath,
  AppRoutes.pricing: AppRoutes.pricingPath,
  AppRoutes.settings: AppRoutes.settingsPath,
  AppRoutes.accessibilitySettings: AppRoutes.accessibilitySettingsPath,
  AppRoutes.aboutLicense: AppRoutes.aboutLicensePath,
  AppRoutes.updateProfile: AppRoutes.updateProfilePath,
};

/// Maps a route name to the cold-start restore path, or null when the route
/// must never become the restore point.
String? pathForLastRouteName(String? name) {
  if (name == null) {
    return null;
  }
  return _restorablePathsByRouteName[name];
}

/// Sanitizes a stored `nav.last_route` value read back at cold start
/// (lib/bootstrap.dart), or null when there is nothing restorable so the
/// caller keeps its own no-saved-route behavior.
///
/// Builds before the write-side allowlist persisted flow and gate routes
/// verbatim; a device that still holds one of those values must not
/// cold-start into a screen with no back affordance. Any path the write side
/// would not persist today — every legacy `/auth/*`, `/onboarding`, lock,
/// passcode, force-update and splash value, and anything unrecognized —
/// falls back to [fallback].
String? sanitizeStoredLastRoute(String? stored, {String fallback = AppRoutes.homePath}) {
  if (stored == null || stored.isEmpty) {
    return null;
  }
  return _restorablePathsByRouteName.containsValue(stored) ? stored : fallback;
}

final class LastRouteObserver extends NavigatorObserver {
  LastRouteObserver({required SettingsStore store, AppLogger? logger})
    : _store = store,
      _logger = logger ?? AppLogger.bootstrap();

  final SettingsStore _store;

  final AppLogger _logger;

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
    unawaited(
      runGuarded(
        () => _store.writeString(lastRouteKey, path),
        logger: _logger,
        label: 'last_route.persist',
      ),
    );
  }
}
