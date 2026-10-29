import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:starter/app/app.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/config/app_environment.dart';
import 'package:starter/app/dependencies.dart';
import 'package:starter/app/last_route.dart';
import 'package:starter/app/routing/app_link_handler.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/features/announcements/announcement_fixtures.dart';
import 'package:starter/features/session/auth_session.dart';
import 'package:starter/features/settings/in_memory_settings_store.dart';
import 'package:starter/i18n/translations.g.dart';

import '../support/pump_app_frames.dart';

/// The boilerplate has no hard login: an anonymous session opening
/// /profile/edit must land on the profile page's sign-in state, never be
/// redirected to /auth/login, and an auth visit must never become the
/// cold-start restore point (lib/app/last_route.dart).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => LocaleSettings.setLocale(AppLocale.en));

  testWidgets('an anonymous session navigating to /profile/edit lands on the profile page', (
    tester,
  ) async {
    await _pumpApp(tester, initialLocation: AppRoutes.homePath);

    GoRouter.of(
      tester.element(find.byType(Navigator).first),
    ).go(AppRoutes.updateProfilePath);
    await pumpAppFrames(tester);

    expect(
      GoRouter.of(
        tester.element(find.byType(Navigator).first),
      ).routeInformationProvider.value.uri.path,
      AppRoutes.updateProfilePath,
    );
    expect(
      find.byKey(const ValueKey('profile-anonymous')),
      findsOneWidget,
      reason: 'anonymous sessions get the graceful sign-in state, not a redirect',
    );
    expect(
      find.byKey(const ValueKey('auth-login-form')),
      findsNothing,
      reason: 'no hard login: the router must not bounce to /auth/login',
    );
  });

  testWidgets('the anonymous profile state offers sign-in and an explicit way back to home', (
    tester,
  ) async {
    await _pumpApp(tester, initialLocation: AppRoutes.homePath);
    GoRouter.of(
      tester.element(find.byType(Navigator).first),
    ).go(AppRoutes.updateProfilePath);
    await pumpAppFrames(tester);

    expect(find.byKey(const ValueKey('profile-anonymous-sign-in')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-anonymous-continue')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('profile-anonymous-continue')));
    await pumpAppFrames(tester);

    expect(
      GoRouter.of(
        tester.element(find.byType(Navigator).first),
      ).routeInformationProvider.value.uri.path,
      AppRoutes.homePath,
    );
    expect(find.byKey(const ValueKey('home-greeting')), findsOneWidget);
  });

  testWidgets('an authenticated session still gets the edit form on /profile/edit', (tester) async {
    await _pumpApp(tester, initialLocation: AppRoutes.homePath, initialSession: _authenticated);

    GoRouter.of(
      tester.element(find.byType(Navigator).first),
    ).go(AppRoutes.updateProfilePath);
    await pumpAppFrames(tester);

    expect(
      GoRouter.of(
        tester.element(find.byType(Navigator).first),
      ).routeInformationProvider.value.uri.path,
      AppRoutes.updateProfilePath,
    );
    expect(find.byKey(const ValueKey('profile-save')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-anonymous')), findsNothing);
  });

  testWidgets('a /auth/login visit is not persisted as the cold-start restore point', (
    tester,
  ) async {
    final settingsStore = InMemorySettingsStore();
    await _pumpApp(
      tester,
      initialLocation: AppRoutes.homePath,
      settingsStore: settingsStore,
    );

    GoRouter.of(
      tester.element(find.byType(Navigator).first),
    ).go(AppRoutes.loginPath);
    await pumpAppFrames(tester);
    expect(
      find.byKey(const ValueKey('auth-login-form')),
      findsOneWidget,
      reason: 'the flow under test really visited the login page',
    );

    expect(
      settingsStore.snapshot[lastRouteKey],
      isNot(AppRoutes.loginPath),
      reason: 'persisting /auth/login would strand every later cold start on the login flow',
    );

    // Relaunch: bootstrap restores from the persisted value; the user must
    // land back on the last valid route, not the login flow.
    final restoredLocation = settingsStore.snapshot[lastRouteKey];
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpAppFrames(tester);
    await _pumpApp(
      tester,
      initialLocation: restoredLocation ?? AppRoutes.homePath,
      settingsStore: settingsStore,
    );

    expect(
      find.byKey(const ValueKey('auth-login-form')),
      findsNothing,
      reason: 'a cold start must never restore into the login flow',
    );
    expect(find.byKey(const ValueKey('home-greeting')), findsOneWidget);
  });
}

final _developmentConfig = AppConfig(
  environment: AppEnvironment.development,
  enableVerboseLogging: true,
  enableDevTools: true,
  iosAppleId: '',
  allowedDeepLinkHosts: AllowedDeepLinkHosts.empty,
);

final _authenticated = AuthAuthenticated(
  accessToken: 'test-access-token',
  refreshToken: 'test-refresh-token',
  expiresAt: DateTime.utc(9999, 12, 31),
  userId: 'test-user',
);

Future<void> _pumpApp(
  WidgetTester tester, {
  required String initialLocation,
  InMemorySettingsStore? settingsStore,
  AuthSession? initialSession,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await LocaleSettings.setLocale(AppLocale.en);
  await tester.pumpWidget(
    App(
      config: _developmentConfig,
      dependencies: AppDependencies.inMemory(
        settingsStore: settingsStore,
        initialSession: initialSession,
        dismissedAnnouncementIds: AnnouncementFixtures.standard.map((a) => a.id).toSet(),
      ),
      initialLocation: initialLocation,
    ),
  );
  await tester.pumpAndSettle();
}
