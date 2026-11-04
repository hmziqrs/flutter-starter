import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/app/app.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/config/app_environment.dart';
import 'package:starter/app/dependencies.dart';
import 'package:starter/app/routing/app_link_handler.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/app/routing/otp_purpose.dart';
import 'package:starter/features/session/auth_session.dart';
import 'package:starter/i18n/translations.g.dart';
import '../support/pump_app_frames.dart';

void main() {
  final productionRoutes = <(String, String)>[
    (AppRoutes.homePath, 'Welcome, Alex'),
    (AppRoutes.settingsPath, 'Settings'),
    (AppRoutes.appearanceSettingsPath, 'Appearance'),
    (AppRoutes.languageSettingsPath, 'Language'),
    (AppRoutes.pricingPath, 'Plans for the way you work'),
    (AppRoutes.onboardingPath, 'Build from a durable foundation'),
    (AppRoutes.onboardingPaywallPath, 'Keep building with more room'),
    (AppRoutes.loginPath, 'Welcome back'),
    (AppRoutes.registerPath, 'Create your account'),
    (AppRoutes.forgotPasswordPath, 'Reset your password'),
    (AppRoutes.otpLocation(OtpPurpose.registration), 'Verify your registration'),
    (AppRoutes.otpLocation(OtpPurpose.passwordReset), 'Verify your reset request'),
    (AppRoutes.resetPasswordPath, 'Choose a new password'),
    (AppRoutes.updateProfilePath, 'Update profile'),
  ];

  for (final (location, title) in productionRoutes) {
    testWidgets('$location is directly addressable in production', (tester) async {
      await LocaleSettings.setLocale(AppLocale.en);
      await tester.pumpWidget(
        App(
          config: _productionConfig,
          dependencies: AppDependencies.inMemory(
            initialSession: location == AppRoutes.updateProfilePath ? _authenticatedSession : null,
          ),
          initialLocation: location,
        ),
      );
      await pumpAppFrames(tester);

      expect(find.text(title), findsWidgets);
      expect(find.byKey(const ValueKey('route-error-home')), findsNothing);
    });
  }

  group('announcements stay inside the shell', () {
    final title = find.text('Welcome to the starter');

    for (final location in [AppRoutes.homePath, AppRoutes.settingsPath]) {
      testWidgets('$location shows the announcement', (tester) async {
        await LocaleSettings.setLocale(AppLocale.en);
        await tester.pumpWidget(
          App(
            config: _developmentToolsConfig,
            dependencies: AppDependencies.inMemory(),
            initialLocation: location,
          ),
        );
        await pumpAppFrames(tester);

        expect(title, findsOneWidget);
      });
    }

    for (final location in [
      AppRoutes.loginPath,
      AppRoutes.forceUpdatePath,
      AppRoutes.onboardingPath,
      AppRoutes.biometricLockPath,
    ]) {
      testWidgets('$location does not show the announcement', (tester) async {
        await LocaleSettings.setLocale(AppLocale.en);
        await tester.pumpWidget(
          App(
            config: _developmentToolsConfig,
            dependencies: AppDependencies.inMemory(),
            initialLocation: location,
          ),
        );
        await pumpAppFrames(tester);

        expect(title, findsNothing);
      });
    }
  });

  testWidgets('an OTP address opened directly starts without a failure notice', (tester) async {
    await LocaleSettings.setLocale(AppLocale.en);
    await tester.pumpWidget(
      App(
        config: _productionConfig,
        dependencies: AppDependencies.inMemory(),
        initialLocation: AppRoutes.otpLocation(OtpPurpose.registration),
      ),
    );
    await pumpAppFrames(tester);

    expect(find.byKey(const ValueKey('auth-otp-global-failure')), findsNothing);
  });

  testWidgets('missing and malformed OTP purposes use localized recovery', (tester) async {
    await LocaleSettings.setLocale(AppLocale.en);
    await tester.pumpWidget(
      App(
        config: _productionConfig,
        dependencies: AppDependencies.inMemory(),
        initialLocation: '/auth/otp/not-valid',
      ),
    );
    await pumpAppFrames(tester);

    expect(
      find.text(
        'The verification address needs a valid registration or password-reset purpose.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('route-error-back')), findsNothing);

    await tester.pumpWidget(
      App(
        config: _productionConfig,
        dependencies: AppDependencies.inMemory(),
        initialLocation: '/auth/otp',
      ),
    );
    await pumpAppFrames(tester);

    expect(find.text('We could not open that page'), findsOneWidget);
    expect(find.byKey(const ValueKey('route-error-back')), findsNothing);
  });

  testWidgets('both development routes are absent from production', (tester) async {
    await LocaleSettings.setLocale(AppLocale.en);
    for (final location in [
      AppRoutes.developmentScreensPath,
      AppRoutes.diagnosticsPath,
    ]) {
      await tester.pumpWidget(
        App(
          config: _productionConfig,
          dependencies: AppDependencies.inMemory(),
          initialLocation: location,
        ),
      );
      await pumpAppFrames(tester);

      expect(find.text('We could not open that page'), findsOneWidget);
    }
  });
}

final _productionConfig = AppConfig(
  environment: AppEnvironment.production,
  enableVerboseLogging: false,
  enableDevTools: false,
  iosAppleId: '',
  allowedDeepLinkHosts: AllowedDeepLinkHosts.empty,
);

final _authenticatedSession = AuthAuthenticated(
  accessToken: 'test-access-token',
  refreshToken: 'test-refresh-token',
  expiresAt: DateTime.utc(9999, 12, 31),
  userId: 'test-user',
);

// Announcement fixtures only run in development builds.
final _developmentToolsConfig = AppConfig(
  environment: AppEnvironment.development,
  enableVerboseLogging: false,
  enableDevTools: true,
  iosAppleId: '',
  allowedDeepLinkHosts: AllowedDeepLinkHosts.empty,
);
