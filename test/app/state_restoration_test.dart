import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/app/app.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/config/app_environment.dart';
import 'package:starter/app/dependencies.dart';
import 'package:starter/app/dependencies/dependency_aggregates.dart';
import 'package:starter/app/last_route.dart';
import 'package:starter/app/routing/app_link_handler.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/features/force_update/update_requirement.dart';
import 'package:starter/features/settings/in_memory_settings_store.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/features/settings/settings_store.dart';

import 'support/pump_app_frames.dart';

void main() {
  group('lastRouteKey', () {
    test('is a stable, namespaced settings key', () {
      expect(lastRouteKey, 'nav.last_route');
    });
  });

  group('pathForLastRouteName', () {
    test('resolves known route names to their path constant', () {
      expect(pathForLastRouteName(AppRoutes.home), AppRoutes.homePath);
      expect(pathForLastRouteName(AppRoutes.updateProfile), AppRoutes.updateProfilePath);
      expect(pathForLastRouteName(AppRoutes.settings), AppRoutes.settingsPath);
      expect(pathForLastRouteName(AppRoutes.pricing), AppRoutes.pricingPath);
    });

    test('never persists auth flow routes (would strand cold start on /auth/login)', () {
      expect(pathForLastRouteName(AppRoutes.login), isNull);
      expect(pathForLastRouteName(AppRoutes.register), isNull);
      expect(pathForLastRouteName(AppRoutes.forgotPassword), isNull);
      expect(pathForLastRouteName(AppRoutes.resetPassword), isNull);
    });

    test('never persists onboarding flow routes', () {
      expect(pathForLastRouteName(AppRoutes.onboarding), isNull);
      expect(pathForLastRouteName(AppRoutes.onboardingPaywall), isNull);
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
      expect(pathForLastRouteName(AppRoutes.passcodeEntry), isNull);
      expect(pathForLastRouteName(AppRoutes.passcodeSetup), isNull);
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

      LastRouteObserver(store: store).didPush(_route(AppRoutes.home), null);

      expect(store.snapshot[lastRouteKey], AppRoutes.homePath);
    });

    test('updates the stored path as the user navigates', () async {
      final store = InMemorySettingsStore();

      LastRouteObserver(store: store)
        ..didPush(_route(AppRoutes.home), null)
        ..didPush(_route(AppRoutes.settings), _route(AppRoutes.home));

      expect(store.snapshot[lastRouteKey], AppRoutes.settingsPath);
    });

    test('persists the previous (returned-to) route on didPop', () async {
      final store = InMemorySettingsStore();

      LastRouteObserver(store: store)
        ..didPush(_route(AppRoutes.settings), null)
        ..didPush(_route(AppRoutes.aboutLicense), _route(AppRoutes.settings))
        ..didPop(_route(AppRoutes.aboutLicense), _route(AppRoutes.settings));

      expect(store.snapshot[lastRouteKey], AppRoutes.settingsPath);
    });

    test('never persists auth visits — the restore point stays the last valid route', () async {
      final store = InMemorySettingsStore();

      // One visit to the login flow must not strand a later cold start on it.
      LastRouteObserver(store: store)
        ..didPush(_route(AppRoutes.home), null)
        ..didPush(_route(AppRoutes.login), _route(AppRoutes.home))
        ..didPush(_route(AppRoutes.register), _route(AppRoutes.login))
        ..didPush(_route(AppRoutes.forgotPassword), _route(AppRoutes.register));

      expect(store.snapshot[lastRouteKey], AppRoutes.homePath);
    });

    test(
      'never persists onboarding visits — the restore point stays the last valid route',
      () async {
        final store = InMemorySettingsStore();

        LastRouteObserver(store: store)
          ..didPush(_route(AppRoutes.pricing), null)
          ..didPush(_route(AppRoutes.onboarding), _route(AppRoutes.pricing))
          ..didPush(_route(AppRoutes.onboardingPaywall), _route(AppRoutes.onboarding));

        expect(store.snapshot[lastRouteKey], AppRoutes.pricingPath);
      },
    );

    test('ignores excluded routes (splash) so relaunch never loops', () async {
      final store = InMemorySettingsStore();

      LastRouteObserver(store: store)
        ..didPush(_route(AppRoutes.home), null)
        ..didPush(_route(AppRoutes.splash), _route(AppRoutes.home));

      expect(store.snapshot[lastRouteKey], AppRoutes.homePath);
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
      expect(counting.writes, 1);
    });

    test('never throws and never blocks when the store fails', () async {
      final store = InMemorySettingsStore()..failWrites = true;
      final observer = LastRouteObserver(store: store);

      expect(() => observer.didPush(_route(AppRoutes.login), null), returnsNormally);
    });
  });

  group('restorationScopeId', () {
    final developmentConfig = AppConfig(
      environment: AppEnvironment.development,
      enableVerboseLogging: true,
      enableDevTools: true,
      iosAppleId: '',
      allowedDeepLinkHosts: AllowedDeepLinkHosts.empty,
    );

    test('the shared scope id stays the stable documented literal', () {
      expect(appRestorationScopeId, 'app');
    });

    testWidgets('the root MaterialApp restores under the shared scope id', (tester) async {
      await tester.pumpWidget(
        App(config: developmentConfig, dependencies: AppDependencies.inMemory()),
      );
      await pumpAppFrames(tester);

      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).restorationScopeId,
        appRestorationScopeId,
      );
    });
  });

  group('saved last route vs. gate precedence', () {
    final developmentConfig = AppConfig(
      environment: AppEnvironment.development,
      enableVerboseLogging: true,
      enableDevTools: true,
      iosAppleId: '',
      allowedDeepLinkHosts: AllowedDeepLinkHosts.empty,
    );

    testWidgets('the onboarding gate wins over a saved last-route location', (tester) async {
      await tester.pumpWidget(
        App(
          config: developmentConfig,
          dependencies: AppDependencies.inMemory(
            initialSettings: const SettingsState.defaults().copyWith(
              hasCompletedOnboarding: false,
            ),
          ),
          initialLocation: AppRoutes.pricingPath,
        ),
      );
      await pumpAppFrames(tester);

      expect(find.byKey(const ValueKey('onboarding-pager')), findsOneWidget);
      expect(find.byKey(const ValueKey('pricing-page')), findsNothing);
    });

    testWidgets('a hard update requirement wins over a saved last-route location', (
      tester,
    ) async {
      final base = AppDependencies.inMemory();
      final blocked = AppDependencies(
        logger: base.logger,
        settings: base.settings,
        storage: base.storage,
        auth: base.auth,
        telemetry: base.telemetry,
        remoteConfig: RemoteConfigDependencies(
          versionGateStore: base.remoteConfig.versionGateStore,
          versionCheck: const UpdateRequirement.hard(
            minVersion: '2.0.0',
            latestVersion: '2.0.0',
            storeUrl: 'https://example.com/update',
          ),
          featureFlagsSource: base.remoteConfig.featureFlagsSource,
          experimentSource: base.remoteConfig.experimentSource,
        ),
        notifications: base.notifications,
        feedback: base.feedback,
        platform: base.platform,
        appStartupResult: base.appStartupResult,
        initialDismissedAnnouncementIds: base.initialDismissedAnnouncementIds,
      );

      await tester.pumpWidget(
        App(
          config: developmentConfig,
          dependencies: blocked,
          initialLocation: AppRoutes.pricingPath,
        ),
      );
      await pumpAppFrames(tester);

      expect(find.byKey(const ValueKey('force-update-title')), findsOneWidget);
      expect(find.byKey(const ValueKey('pricing-page')), findsNothing);
    });
  });
}

Route<dynamic> _route(String? name) {
  return MaterialPageRoute<void>(
    settings: RouteSettings(name: name),
    builder: (_) => const SizedBox.shrink(),
  );
}

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
