import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/app/last_route.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/features/settings/in_memory_settings_store.dart';
import 'package:starter/features/settings/settings_store.dart';

/// State-restoration spec — last-route persistence + restoration-scope wiring.
///
/// These tests cover the OPTIONAL last-route sub-feature: the
/// [LastRouteObserver] writes the latest restorable route path to a
/// [SettingsStore] key, and [pathForLastRouteName] maps the route name a
/// `NavigatorObserver` sees back to that path. The C5 redirect chain
/// (update/onboarding/session/biometric) re-evaluates after `initialLocation` is
/// set in bootstrap, so a saved route never overrides a hard block or a fresh
/// install's onboarding — that precedence is covered by the existing redirect
/// tests in test/app/routing/.
void main() {
  group('lastRouteKey', () {
    test('is a stable, namespaced settings key', () {
      // The key must stay stable across releases: changing it orphans any saved
      // last-route value (the same contract as SoftUpdateSnooze.key).
      expect(lastRouteKey, 'nav.last_route');
    });
  });

  group('pathForLastRouteName', () {
    test('resolves known route names to their path constant', () {
      expect(pathForLastRouteName(AppRoutes.home), AppRoutes.homePath);
      expect(pathForLastRouteName(AppRoutes.login), AppRoutes.loginPath);
      expect(pathForLastRouteName(AppRoutes.register), AppRoutes.registerPath);
      expect(pathForLastRouteName(AppRoutes.forgotPassword), AppRoutes.forgotPasswordPath);
      expect(pathForLastRouteName(AppRoutes.resetPassword), AppRoutes.resetPasswordPath);
      expect(pathForLastRouteName(AppRoutes.updateProfile), AppRoutes.updateProfilePath);
      expect(pathForLastRouteName(AppRoutes.settings), AppRoutes.settingsPath);
      expect(pathForLastRouteName(AppRoutes.pricing), AppRoutes.pricingPath);
      expect(pathForLastRouteName(AppRoutes.onboarding), AppRoutes.onboardingPath);
      expect(pathForLastRouteName(AppRoutes.onboardingPaywall), AppRoutes.onboardingPaywallPath);
    });

    test('never persists the cold-start splash (would loop relaunch into splash)', () {
      expect(pathForLastRouteName(AppRoutes.splash), isNull);
    });

    test(
      'never persists dev-only routes (gated by developmentToolsEnabled)',
      () {
        expect(pathForLastRouteName(AppRoutes.developmentScreens), isNull);
        expect(pathForLastRouteName(AppRoutes.diagnostics), isNull);
      },
    );

    test('never persists the dynamic OTP route (name lacks the :purpose)', () {
      expect(pathForLastRouteName(AppRoutes.otp), isNull);
    });

    test('never persists gate routes the C5 redirect re-evaluates anyway', () {
      expect(pathForLastRouteName(AppRoutes.forceUpdate), isNull);
      expect(pathForLastRouteName(AppRoutes.biometricLock), isNull);
    });

    test(
      'never persists redirect-normalized settings sub-routes (rewritten to /settings)',
      () {
        expect(pathForLastRouteName(AppRoutes.appearanceSettings), isNull);
        expect(pathForLastRouteName(AppRoutes.languageSettings), isNull);
      },
    );

    test('returns null for unknown / null names so stale links never strand', () {
      expect(pathForLastRouteName(null), isNull);
      expect(pathForLastRouteName('not-a-real-route'), isNull);
      expect(pathForLastRouteName(''), isNull);
    });
  });

  group('LastRouteObserver', () {
    test('writes the resolved path to the store on didPush', () async {
      final store = InMemorySettingsStore();

      LastRouteObserver(store: store).didPush(_route(AppRoutes.login), null);

      expect(store.snapshot[lastRouteKey], AppRoutes.loginPath);
    });

    test('updates the stored path as the user navigates', () async {
      final store = InMemorySettingsStore();

      LastRouteObserver(store: store)
        ..didPush(_route(AppRoutes.login), null)
        ..didPush(_route(AppRoutes.forgotPassword), _route(AppRoutes.login));

      expect(store.snapshot[lastRouteKey], AppRoutes.forgotPasswordPath);
    });

    test('persists the previous (returned-to) route on didPop', () async {
      final store = InMemorySettingsStore();

      LastRouteObserver(store: store)
        ..didPush(_route(AppRoutes.login), null)
        ..didPush(_route(AppRoutes.register), _route(AppRoutes.login))
        // Pop register -> back to login. The observer should persist login.
        ..didPop(_route(AppRoutes.register), _route(AppRoutes.login));

      expect(store.snapshot[lastRouteKey], AppRoutes.loginPath);
    });

    test('ignores excluded routes (splash) so relaunch never loops', () async {
      final store = InMemorySettingsStore();

      LastRouteObserver(store: store)
        ..didPush(_route(AppRoutes.login), null)
        ..didPush(_route(AppRoutes.splash), _route(AppRoutes.login));

      // Splash is excluded; the previously-saved login path stays.
      expect(store.snapshot[lastRouteKey], AppRoutes.loginPath);
    });

    test('ignores routes with no settings name', () async {
      final store = InMemorySettingsStore();

      LastRouteObserver(store: store).didPush(_route(null), null);

      expect(store.snapshot.containsKey(lastRouteKey), isFalse);
    });

    test('dedups consecutive identical writes to avoid disk churn', () async {
      final store = InMemorySettingsStore();
      final counting = _CountingSettingsStore(store);

      LastRouteObserver(store: counting)
        ..didPush(_route(AppRoutes.home), null)
        ..didPush(_route(AppRoutes.home), null);

      expect(store.snapshot[lastRouteKey], AppRoutes.homePath);
      // Two consecutive identical pushes produced exactly one write.
      expect(counting.writes, 1);
    });

    test('never throws and never blocks when the store fails', () async {
      final store = InMemorySettingsStore()..failWrites = true;
      final observer = LastRouteObserver(store: store);

      // A failing write degrades honestly to "no saved route" and must not
      // propagate (navigation is never blocked by persistence).
      expect(() => observer.didPush(_route(AppRoutes.login), null), returnsNormally);
    });
  });
}

Route<dynamic> _route(String? name) {
  return MaterialPageRoute<void>(
    settings: RouteSettings(name: name),
    builder: (_) => const SizedBox.shrink(),
  );
}

/// Counts [SettingsStore.writeString] invocations by delegating to a real store.
class _CountingSettingsStore implements SettingsStore {
  _CountingSettingsStore(this._inner);

  final SettingsStore _inner;
  int writes = 0;

  @override
  Future<String?> readString(String key) => _inner.readString(key);

  @override
  Future<void> remove(String key) => _inner.remove(key);

  @override
  Future<void> writeString(String key, String value) {
    writes += 1;
    return _inner.writeString(key, value);
  }
}
