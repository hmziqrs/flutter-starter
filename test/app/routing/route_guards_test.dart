import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:starter/app/app.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/config/app_environment.dart';
import 'package:starter/app/dependencies.dart';
import 'package:starter/app/dependencies/dependency_aggregates.dart';
import 'package:starter/app/routing/app_link_handler.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/features/force_update/soft_update_dialog.dart';
import 'package:starter/features/force_update/update_requirement.dart';
import 'package:starter/features/settings/in_memory_settings_store.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/i18n/translations.g.dart';

import '../support/pump_app_frames.dart';

/// Router-level coverage for the update-blocker gate composed into `appRedirect`
/// (`lib/app/routing/route_guards.dart`): the `hard` requirement must trap every
/// route on `/force-update` (no pop, no in-session escape), and the `soft`
/// requirement must never redirect, must present its dialog post-frame from the
/// root navigator, and must honor a persisted snooze — including one persisted
/// by tapping Later on a previous launch.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => LocaleSettings.setLocale(AppLocale.en));

  const hardRequirement = UpdateRequirement.hard(
    minVersion: '1.0.0',
    latestVersion: '2.0.0',
    storeUrl: 'https://example.test/store',
  );
  const softRequirement = UpdateRequirement.soft(
    minVersion: '1.5.0',
    latestVersion: '2.0.0',
    storeUrl: 'https://example.test/store',
  );

  testWidgets('hard requirement redirects every route to the force-update page', (
    tester,
  ) async {
    for (final location in [
      AppRoutes.homePath,
      AppRoutes.pricingPath,
      AppRoutes.settingsPath,
      AppRoutes.loginPath,
      AppRoutes.onboardingPath,
    ]) {
      await _pumpGateApp(tester, hardRequirement, initialLocation: location);

      expect(
        find.byKey(const ValueKey('force-update-title')),
        findsOneWidget,
        reason: 'cold start on $location must land on ${AppRoutes.forceUpdatePath}',
      );
      expect(find.byKey(const ValueKey('home-greeting')), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await pumpAppFrames(tester);
    }
  });

  testWidgets('hard block is a trap: in-session navigation cannot leave it', (tester) async {
    await _pumpGateApp(tester, hardRequirement, initialLocation: AppRoutes.homePath);
    expect(find.byKey(const ValueKey('force-update-title')), findsOneWidget);

    final router = GoRouter.of(tester.element(find.byType(Navigator).first));
    for (final target in [
      AppRoutes.homePath,
      AppRoutes.settingsPath,
      AppRoutes.loginPath,
    ]) {
      router.go(target);
      await pumpAppFrames(tester);
      expect(
        find.byKey(const ValueKey('force-update-title')),
        findsOneWidget,
        reason: 'go($target) must be bounced back to the force-update trap',
      );
    }

    expect(router.routeInformationProvider.value.uri.path, AppRoutes.forceUpdatePath);
  });

  testWidgets('hard block is a trap: Escape and TV back never pop the page', (tester) async {
    await _pumpGateApp(tester, hardRequirement, initialLocation: AppRoutes.homePath);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await pumpAppFrames(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.gameButtonB);
    await pumpAppFrames(tester);

    expect(find.byKey(const ValueKey('force-update-title')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-greeting')), findsNothing);
  });

  testWidgets('soft requirement stays on the route and honors a persisted snooze', (
    tester,
  ) async {
    final settingsStore = InMemorySettingsStore(
      seed: {SoftUpdateSnooze.key: SoftUpdateSnooze.encode()},
    );
    await _pumpGateApp(
      tester,
      softRequirement,
      settingsStore: settingsStore,
      initialLocation: AppRoutes.homePath,
    );

    expect(find.byKey(const ValueKey('home-greeting')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('force-update-title')),
      findsNothing,
      reason: 'soft deprecation must never redirect away from the route',
    );
    expect(
      find.byKey(const ValueKey('soft-update-dialog')),
      findsNothing,
      reason: 'an unexpired snooze must suppress the soft prompt on a cold start',
    );
  });

  testWidgets('soft requirement presents the soft-update dialog post-frame', (tester) async {
    await _pumpGateApp(tester, softRequirement, initialLocation: AppRoutes.homePath);

    expect(find.byKey(const ValueKey('home-greeting')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('force-update-title')),
      findsNothing,
      reason: 'soft deprecation must never redirect away from the route',
    );
    expect(
      find.byKey(const ValueKey('soft-update-dialog')),
      findsOneWidget,
      reason: 'a soft deprecation must present the nudge from the root navigator post-frame',
    );
  });

  testWidgets('Later on the soft dialog persists a snooze that survives a relaunch', (
    tester,
  ) async {
    final settingsStore = InMemorySettingsStore();
    await _pumpGateApp(
      tester,
      softRequirement,
      settingsStore: settingsStore,
      initialLocation: AppRoutes.homePath,
    );
    expect(find.byKey(const ValueKey('soft-update-dialog')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('soft-update-later')));
    await pumpAppFrames(tester);
    expect(
      find.byKey(const ValueKey('soft-update-dialog')),
      findsNothing,
      reason: 'Later must dismiss the dialog',
    );

    // Relaunch: a fresh app instance sharing the previously persisted store.
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpAppFrames(tester);
    await _pumpGateApp(
      tester,
      softRequirement,
      settingsStore: settingsStore,
      initialLocation: AppRoutes.homePath,
    );

    expect(find.byKey(const ValueKey('home-greeting')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('soft-update-dialog')),
      findsNothing,
      reason: 'the snooze persisted by Later must suppress the prompt on the next launch',
    );
  });
}

final _productionConfig = AppConfig(
  environment: AppEnvironment.production,
  enableVerboseLogging: false,
  enableDevTools: false,
  iosAppleId: '',
  allowedDeepLinkHosts: AllowedDeepLinkHosts.empty,
);

App _gateApp(
  UpdateRequirement requirement, {
  required String initialLocation,
  InMemorySettingsStore? settingsStore,
}) {
  final base = AppDependencies.inMemory(
    settingsStore: settingsStore,
    initialSettings: const SettingsState.defaults().copyWith(hasCompletedOnboarding: true),
  );
  return App(
    config: _productionConfig,
    initialLocation: initialLocation,
    dependencies: AppDependencies(
      logger: base.logger,
      settings: base.settings,
      storage: base.storage,
      auth: base.auth,
      telemetry: base.telemetry,
      remoteConfig: RemoteConfigDependencies(
        versionGateStore: base.remoteConfig.versionGateStore,
        versionCheck: requirement,
        featureFlagsSource: base.remoteConfig.featureFlagsSource,
        experimentSource: base.remoteConfig.experimentSource,
      ),
      notifications: base.notifications,
      feedback: base.feedback,
      platform: base.platform,
      appStartupResult: base.appStartupResult,
      initialDismissedAnnouncementIds: base.initialDismissedAnnouncementIds,
    ),
  );
}

Future<void> _pumpGateApp(
  WidgetTester tester,
  UpdateRequirement requirement, {
  required String initialLocation,
  InMemorySettingsStore? settingsStore,
}) async {
  await tester.pumpWidget(
    _gateApp(
      requirement,
      initialLocation: initialLocation,
      settingsStore: settingsStore,
    ),
  );
  await pumpAppFrames(tester);
}
