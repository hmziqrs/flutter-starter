import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/app/app.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/config/app_environment.dart';
import 'package:starter/app/dependencies.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/app/routing/otp_purpose.dart';
import 'package:starter/i18n/translations.g.dart';

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
          dependencies: AppDependencies.inMemory(),
          initialLocation: location,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(title), findsWidgets);
      expect(find.byKey(const ValueKey('route-error-home')), findsNothing);
    });
  }

  testWidgets('missing and malformed OTP purposes use localized recovery', (tester) async {
    await LocaleSettings.setLocale(AppLocale.en);
    await tester.pumpWidget(
      App(
        config: _productionConfig,
        dependencies: AppDependencies.inMemory(),
        initialLocation: '/auth/otp/not-valid',
      ),
    );
    await tester.pumpAndSettle();

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
    await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

      expect(find.text('We could not open that page'), findsOneWidget);
    }
  });
}

final _productionConfig = AppConfig(
  environment: AppEnvironment.production,
  enableVerboseLogging: false,
  enableDevTools: false,
);
