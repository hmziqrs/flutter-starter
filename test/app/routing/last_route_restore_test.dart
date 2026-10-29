import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/app/app.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/config/app_environment.dart';
import 'package:starter/app/dependencies.dart';
import 'package:starter/app/last_route.dart';
import 'package:starter/app/routing/app_link_handler.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/app/routing/otp_purpose.dart';
import 'package:starter/features/announcements/announcement_fixtures.dart';
import 'package:starter/features/settings/in_memory_settings_store.dart';
import 'package:starter/i18n/translations.g.dart';

import '../support/pump_app_frames.dart';

/// Cold-start restore sanitization for `nav.last_route`.
///
/// [sanitizeStoredLastRoute] is the read-side half of the write-side allowlist
/// in [pathForLastRouteName] (lib/app/last_route.dart): builds before that
/// allowlist persisted flow and gate routes verbatim (every `/auth/*` page,
/// `/onboarding`, `/lock`, `/passcode`, `/force-update`), so a device that
/// still holds one of those values must not cold-start into a screen with no
/// back affordance.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => LocaleSettings.setLocale(AppLocale.en));

  group('sanitizeStoredLastRoute', () {
    test('keeps every path the write side persists today', () {
      for (final path in <String>[
        AppRoutes.homePath,
        AppRoutes.pricingPath,
        AppRoutes.settingsPath,
        AppRoutes.accessibilitySettingsPath,
        AppRoutes.aboutLicensePath,
        AppRoutes.updateProfilePath,
      ]) {
        expect(sanitizeStoredLastRoute(path), path, reason: '$path is a valid restore point');
      }
    });

    test('falls back to home for legacy flow, gate, and unrecognized values', () {
      for (final stale in <String>[
        AppRoutes.loginPath,
        AppRoutes.registerPath,
        AppRoutes.forgotPasswordPath,
        AppRoutes.resetPasswordPath,
        AppRoutes.otpLocation(OtpPurpose.registration),
        AppRoutes.otpLocation(OtpPurpose.passwordReset),
        AppRoutes.onboardingPath,
        AppRoutes.onboardingPaywallPath,
        AppRoutes.biometricLockPath,
        AppRoutes.passcodeEntryPath,
        AppRoutes.passcodeSetupPath,
        AppRoutes.forceUpdatePath,
        AppRoutes.splashPath,
        AppRoutes.developmentScreensPath,
        '/no-such-route',
      ]) {
        expect(
          sanitizeStoredLastRoute(stale),
          AppRoutes.homePath,
          reason: 'a stale $stale value must never become the restore point',
        );
      }
    });

    test('returns null for absent values so the caller keeps its default', () {
      expect(sanitizeStoredLastRoute(null), isNull);
      expect(sanitizeStoredLastRoute(''), isNull);
    });
  });

  testWidgets('a stale /auth/login restore value cold-starts on home, not the login flow', (
    tester,
  ) async {
    // The value a pre-allowlist build could have left on the device.
    final settingsStore = InMemorySettingsStore(seed: {lastRouteKey: AppRoutes.loginPath});

    // bootstrap.dart reads nav.last_route and feeds it through
    // sanitizeStoredLastRoute; reproduce that exact expression because
    // createApplication needs the production dependency graph.
    final restored = sanitizeStoredLastRoute(settingsStore.snapshot[lastRouteKey]);
    expect(restored, AppRoutes.homePath);

    await _pumpApp(tester, initialLocation: restored!);

    expect(
      find.byKey(const ValueKey('auth-login-form')),
      findsNothing,
      reason: 'a legacy /auth/login value must not cold-start into the login flow',
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

Future<void> _pumpApp(WidgetTester tester, {required String initialLocation}) async {
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
        settingsStore: InMemorySettingsStore(),
        dismissedAnnouncementIds: AnnouncementFixtures.standard.map((a) => a.id).toSet(),
      ),
      initialLocation: initialLocation,
    ),
  );
  await pumpAppFrames(tester);
}
