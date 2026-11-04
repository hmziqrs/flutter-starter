import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/app/app.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/config/app_environment.dart';
import 'package:starter/app/dependencies.dart';
import 'package:starter/app/routing/app_link_handler.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/app/routing/otp_purpose.dart';
import 'package:starter/features/session/auth_session.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/fx/shaders/brand_material_program.dart';
import 'package:starter/shared/fx/shaders/liquid_glass_program.dart';

/// Renders the REAL app (root `App`, router, shell, guards) on every route at
/// phone, tablet and desktop sizes, in dark and light, to
/// `build/visual-screens/`. Gallery cases only ever exercise a page in
/// isolation at one phone size; this is what proves a screen, per the
/// brand-parity rules in AGENTS.md.
///
/// One-off tool, never a baseline: `just visual-screens` renders the set. A
/// plain `flutter test` skips it, because the output folder is gitignored and
/// absent on a clean clone. Layout exceptions are collected per route into
/// `_report.txt` and fail the run at the end, so one bad page cannot hide the
/// renders of the others.
void main() {
  const outputDir = 'build/visual-screens';
  final config = AppConfig(
    environment: AppEnvironment.development,
    enableVerboseLogging: false,
    enableDevTools: true,
    iosAppleId: '',
    allowedDeepLinkHosts: AllowedDeepLinkHosts.empty,
  );
  final session = AuthSession.authenticated(
    accessToken: 'visual-access',
    refreshToken: 'visual-refresh',
    userId: 'visual-user',
    expiresAt: DateTime.utc(2099),
  );

  const viewports = <(String, Size, TargetPlatform)>[
    ('phone', Size(390, 844), TargetPlatform.iOS),
    ('tablet', Size(820, 1180), TargetPlatform.iOS),
    ('desktop', Size(1440, 900), TargetPlatform.macOS),
    // Tall frames show whole-page composition: what follows the first fold.
    ('phone-full', Size(390, 2400), TargetPlatform.iOS),
    ('desktop-full', Size(1440, 2000), TargetPlatform.macOS),
  ];

  final routes = <(String, String)>[
    ('home', AppRoutes.homePath),
    ('pricing', AppRoutes.pricingPath),
    ('settings', AppRoutes.settingsPath),
    ('settings-appearance', '${AppRoutes.settingsPath}?section=appearance'),
    ('settings-language', '${AppRoutes.settingsPath}?section=language'),
    ('settings-accessibility', AppRoutes.accessibilitySettingsPath),
    ('license', AppRoutes.aboutLicensePath),
    ('onboarding', AppRoutes.onboardingPath),
    ('paywall', AppRoutes.onboardingPaywallPath),
    ('login', AppRoutes.loginPath),
    ('register', AppRoutes.registerPath),
    ('forgot', AppRoutes.forgotPasswordPath),
    ('otp', AppRoutes.otpLocation(OtpPurpose.registration)),
    ('reset', AppRoutes.resetPasswordPath),
    ('profile', AppRoutes.updateProfilePath),
    ('search', AppRoutes.searchPath),
    ('passcode', AppRoutes.passcodeSetupPath),
    ('lock', AppRoutes.biometricLockPath),
    ('force-update', AppRoutes.forceUpdatePath),
    ('splash', AppRoutes.splashPath),
    ('not-found', '/definitely-not-a-route'),
    ('diagnostics', AppRoutes.diagnosticsPath),
    ('gallery', AppRoutes.developmentScreensPath),
  ];

  setUpAll(() async {
    Future<void> family(String name, List<String> assets) async {
      final loader = FontLoader(name);
      for (final asset in assets) {
        loader.addFont(rootBundle.load(asset));
      }
      await loader.load();
    }

    await family('Onest', [
      'assets/fonts/Onest/onest-latin-400-normal.ttf',
      'assets/fonts/Onest/onest-latin-500-normal.ttf',
      'assets/fonts/Onest/onest-latin-600-normal.ttf',
    ]);
    await family('JetBrains Mono', [
      'assets/fonts/JetBrains_Mono/jetbrains-mono-latin-400-normal.ttf',
    ]);
    await family('Noto Sans', ['assets/fonts/Noto_Sans/NotoSans.ttf']);
    await family('Noto Sans Arabic', [
      'assets/fonts/Noto_Sans_Arabic/NotoSansArabic.ttf',
    ]);
    final lucide = await rootBundle.load('packages/forui_assets/assets/lucide.ttf');
    await ui.loadFontFromList(
      lucide.buffer.asUint8List(),
      fontFamily: 'packages/forui_assets/ForuiLucideIcons',
    );
    // Shaders load through a real async asset read; resolve them up front so
    // the first frame paints the material rather than its fallback.
    await BrandMaterialProgram.load();
    await LiquidGlassProgram.load();
  });

  final problems = <String>[];

  test('rendered every route without layout exceptions', skip: !autoUpdateGoldenFiles, () {
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  tearDownAll(() {
    if (!autoUpdateGoldenFiles) return;
    File('$outputDir/_report.txt')
      ..createSync(recursive: true)
      ..writeAsStringSync(problems.isEmpty ? 'clean\n' : '${problems.join('\n')}\n');
  });

  for (final (viewportName, size, platform) in viewports) {
    for (final brightness in Brightness.values) {
      for (final (routeName, location) in routes) {
        final id = '$routeName.$viewportName.${brightness.name}';
        testWidgets(id, skip: !autoUpdateGoldenFiles, (tester) async {
          debugDefaultTargetPlatformOverride = platform;
          LocaleSettings.setLocaleSync(AppLocale.en);
          tester.view
            ..devicePixelRatio = 2
            ..physicalSize = size * 2;
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetPhysicalSize);

          final reported = <String>[];
          final previousOnError = FlutterError.onError;
          FlutterError.onError = (details) => reported.add(details.exceptionAsString());

          final boundary = GlobalKey();
          await tester.pumpWidget(
            RepaintBoundary(
              key: boundary,
              child: App(
                config: config,
                dependencies: AppDependencies.inMemory(
                  initialSettings: const SettingsState.defaults().copyWith(
                    hasCompletedOnboarding: true,
                    themeMode: brightness == Brightness.dark
                        ? AppThemeMode.dark
                        : AppThemeMode.light,
                  ),
                  initialSession: routeName == 'profile' ? session : null,
                ),
                initialLocation: location,
              ),
            ),
          );
          for (var frame = 0; frame < 12; frame += 1) {
            await tester.pump(const Duration(milliseconds: 100));
          }

          final captured = tester.takeException();
          if (captured != null) reported.add(captured.toString());
          FlutterError.onError = previousOnError;
          if (reported.isNotEmpty) {
            problems.add('$id: ${reported.map((e) => e.split('\n').first).toSet().join(' | ')}');
          }

          await expectLater(
            find.byKey(boundary),
            matchesGoldenFile('../../$outputDir/$id.png'),
          );

          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
          debugDefaultTargetPlatformOverride = null;
        });
      }
    }
  }
}
