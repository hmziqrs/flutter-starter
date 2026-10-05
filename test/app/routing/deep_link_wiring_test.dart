import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:starter/app/app.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/config/app_environment.dart';
import 'package:starter/app/dependencies.dart';
import 'package:starter/app/routing/app_link_handler.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/app/routing/otp_purpose.dart';
import 'package:starter/bootstrap.dart';
import 'package:starter/features/security/in_memory_secure_store.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/connectivity/static_connectivity_service.dart';

import '../support/pump_app_frames.dart';

const _allowedHosts = AllowedDeepLinkHosts({'link.starter.dev'});

final _config = AppConfig(
  environment: AppEnvironment.development,
  enableVerboseLogging: false,
  enableDevTools: true,
  iosAppleId: '',
  allowedDeepLinkHosts: _allowedHosts,
);

StreamDeepLinkService _streamService(StreamController<Uri> controller, {Uri? initialLink}) {
  return StreamDeepLinkService(
    handler: const RouteAppLinkHandler(allowedHosts: _allowedHosts),
    controller: controller,
    initialLink: initialLink,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('app deep-link stream dispatch', () {
    testWidgets('streamed links land on their named routes; foreign hosts are dropped', (
      tester,
    ) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await LocaleSettings.setLocale(AppLocale.en);

      final controller = StreamController<Uri>.broadcast();
      addTearDown(controller.close);
      await tester.pumpWidget(
        App(
          config: _config,
          dependencies: AppDependencies.inMemory(
            appLinkHandler: _streamService(controller),
          ),
          initialLocation: AppRoutes.homePath,
        ),
      );
      await pumpAppFrames(tester);
      expect(find.byKey(const ValueKey('home-greeting')), findsOneWidget);

      controller.add(Uri.parse('https://link.starter.dev${AppRoutes.pricingPath}'));
      await pumpAppFrames(tester);
      expect(find.byKey(const ValueKey('pricing-page')), findsOneWidget);

      controller.add(
        Uri.parse('https://link.starter.dev${AppRoutes.otpLocation(OtpPurpose.registration)}'),
      );
      await pumpAppFrames(tester);
      expect(find.byKey(const ValueKey('auth-otp-page')), findsOneWidget);

      // A foreign host is rejected by the allowlist, so the router stays put.
      controller.add(Uri.parse('https://evil.example.com${AppRoutes.loginPath}'));
      await pumpAppFrames(tester);
      expect(find.byKey(const ValueKey('auth-otp-page')), findsOneWidget);
      expect(find.byKey(const ValueKey('auth-login-page')), findsNothing);
    });
  });

  group('cold-start deep-link seeding', () {
    test('the resolved initial link seeds the router initial location', () async {
      final previousPrefs = SharedPreferencesAsyncPlatform.instance;
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
      addTearDown(() => SharedPreferencesAsyncPlatform.instance = previousPrefs);
      PackageInfo.setMockInitialValues(
        appName: 'starter',
        packageName: 'starter',
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: '',
      );
      // Desktop capabilities keep SystemChrome quiet inside createApplication.
      final previousPlatform = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = previousPlatform);

      final controller = StreamController<Uri>.broadcast();
      addTearDown(controller.close);

      Future<App> seed(Uri? initialLink) {
        return createApplication(
          _config,
          secureStore: InMemorySecureStore(),
          connectivityService: const StaticConnectivityService(),
          appLinkHandler: _streamService(controller, initialLink: initialLink),
        );
      }

      final otpApp = await seed(
        Uri.parse('https://link.starter.dev${AppRoutes.otpLocation(OtpPurpose.registration)}'),
      );
      expect(otpApp.initialLocation, AppRoutes.otpLocation(OtpPurpose.registration));

      // A foreign host resolves to null and must never seed a location.
      final foreignApp = await seed(Uri.parse('https://evil.example.com${AppRoutes.loginPath}'));
      expect(foreignApp.initialLocation, isNull);
    });
  });
}
