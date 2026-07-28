import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/config/app_environment.dart';
import 'package:starter/app/routing/app_link_handler.dart';
import 'package:starter/features/dev_gallery/cases/production_gallery_cases.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/features/dev_gallery/gallery_environment.dart';
import 'package:starter/features/dev_gallery/system/system_gallery_cases.dart';
import 'package:starter/shared/adaptive/app_interaction_policy.dart';

import 'canonical_golden_harness.dart';

void main() {
  setUpAll(loadCanonicalGoldenFonts);

  final productionCases = buildProductionGalleryCases();
  final systemCases = buildSystemGalleryCases(
    config: AppConfig(
      environment: AppEnvironment.development,
      enableVerboseLogging: true,
      enableDevTools: true,
      iosAppleId: '',
      allowedDeepLinkHosts: AllowedDeepLinkHosts.empty,
    ),
  );
  final cases = [...productionCases, ...systemCases];

  final fixtures = <CanonicalGoldenFixture>[
    _fixture(
      name: 'onboarding_390x844_en_light_first',
      viewport: const Size(390, 844),
      locale: AppLocale.en,
      brightness: Brightness.light,
      galleryCase: _caseById(cases, 'onboarding.first'),
    ),
    _fixture(
      name: 'paywall_390x844_ar_dark_annual',
      viewport: const Size(390, 844),
      locale: AppLocale.ar,
      brightness: Brightness.dark,
      galleryCase: _caseById(cases, 'pricing.paywall.annual'),
    ),
    _fixture(
      name: 'home_1440x900_en_dark_default',
      viewport: const Size(1440, 900),
      locale: AppLocale.en,
      brightness: Brightness.dark,
      interactionPolicy: AppInteractionPolicy.precisionPointer,
      galleryCase: _caseById(cases, 'home.default'),
    ),
    _fixture(
      name: 'settings_800x1000_zh_light_language',
      viewport: const Size(800, 1000),
      locale: AppLocale.zhHans,
      brightness: Brightness.light,
      galleryCase: _caseById(cases, 'settings.language'),
    ),
    _fixture(
      name: 'login_390x844_en_dark_invalid',
      viewport: const Size(390, 844),
      locale: AppLocale.en,
      brightness: Brightness.dark,
      galleryCase: _caseById(cases, 'auth.login.invalid'),
    ),
    _fixture(
      name: 'login_1440x900_ar_light_focused',
      viewport: const Size(1440, 900),
      locale: AppLocale.ar,
      brightness: Brightness.light,
      interactionPolicy: AppInteractionPolicy.precisionPointer,
      galleryCase: _caseById(cases, 'auth.login.focused'),
      focusedFieldKey: const ValueKey('auth-login-email'),
    ),
    _fixture(
      name: 'register_800x1000_zh_light_default',
      viewport: const Size(800, 1000),
      locale: AppLocale.zhHans,
      brightness: Brightness.light,
      galleryCase: _caseById(cases, 'auth.register.idle'),
    ),
    _fixture(
      name: 'otp_390x844_ar_dark_invalid',
      viewport: const Size(390, 844),
      locale: AppLocale.ar,
      brightness: Brightness.dark,
      galleryCase: _caseById(cases, 'auth.otp.registration.invalid'),
    ),
    _fixture(
      name: 'reset_password_700x700_en_light_maximum_text_scale',
      viewport: const Size(700, 700),
      locale: AppLocale.en,
      brightness: Brightness.light,
      interactionPolicy: AppInteractionPolicy.precisionPointer,
      systemTextScale: GallerySystemTextScale.maximumNonlinear,
      galleryCase: _caseById(cases, 'auth.resetPassword.idle'),
    ),
    _fixture(
      name: 'profile_1440x900_en_light_dirty',
      viewport: const Size(1440, 900),
      locale: AppLocale.en,
      brightness: Brightness.light,
      interactionPolicy: AppInteractionPolicy.precisionPointer,
      galleryCase: _caseById(cases, 'profile.update.dirty'),
    ),
    _fixture(
      name: 'pricing_1440x900_en_dark_annual',
      viewport: const Size(1440, 900),
      locale: AppLocale.en,
      brightness: Brightness.dark,
      interactionPolicy: AppInteractionPolicy.precisionPointer,
      galleryCase: _caseById(cases, 'pricing.annual'),
    ),
    _fixture(
      name: 'route_error_390x844_ar_light_malformed_otp',
      viewport: const Size(390, 844),
      locale: AppLocale.ar,
      brightness: Brightness.light,
      galleryCase: _caseById(cases, 'system.malformedOtp'),
    ),
    _fixture(
      name: 'startup_failure_700x700_en_dark_recoverable',
      viewport: const Size(700, 700),
      locale: AppLocale.en,
      brightness: Brightness.dark,
      interactionPolicy: AppInteractionPolicy.precisionPointer,
      galleryCase: _caseById(cases, 'system.startupFailure'),
    ),
  ];

  test('matrix contains the exact 13 intentional pairwise fixtures', () {
    expect(fixtures, hasLength(13));
    expect(fixtures.map((fixture) => fixture.name).toSet(), hasLength(13));
  });

  for (final fixture in fixtures) {
    testWidgets(fixture.name, (tester) async {
      await expectCanonicalGolden(tester, fixture);
    });
  }
}

CanonicalGoldenFixture _fixture({
  required String name,
  required Size viewport,
  required AppLocale locale,
  required Brightness brightness,
  required GalleryCase galleryCase,
  AppInteractionPolicy interactionPolicy = AppInteractionPolicy.touch,
  GallerySystemTextScale systemTextScale = GallerySystemTextScale.normal,
  Key? focusedFieldKey,
}) {
  return CanonicalGoldenFixture(
    name: name,
    viewport: viewport,
    locale: locale,
    brightness: brightness,
    interactionPolicy: interactionPolicy,
    galleryCase: galleryCase,
    systemTextScale: systemTextScale,
    focusedFieldKey: focusedFieldKey,
  );
}

GalleryCase _caseById(List<GalleryCase> cases, String id) {
  return cases.singleWhere((galleryCase) => galleryCase.id == id);
}
