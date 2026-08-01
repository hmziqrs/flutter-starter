import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/app/routing/otp_purpose.dart';
import 'package:starter/features/auth/forgot_password_page.dart';
import 'package:starter/features/auth/login_page.dart';
import 'package:starter/features/auth/login_presentation_state.dart';
import 'package:starter/features/auth/otp_page.dart';
import 'package:starter/features/auth/otp_presentation_state.dart';
import 'package:starter/features/auth/register_page.dart';
import 'package:starter/features/auth/reset_password_page.dart';
import 'package:starter/features/dev_gallery/cases/production_gallery_cases.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/features/home/home_page.dart';
import 'package:starter/features/home/home_view_data.dart';
import 'package:starter/features/onboarding/onboarding_page.dart';
import 'package:starter/features/pricing/paywall_page.dart';
import 'package:starter/features/pricing/plan_view_data.dart';
import 'package:starter/features/pricing/pricing_page.dart';
import 'package:starter/features/profile/profile_view_data.dart';
import 'package:starter/features/profile/update_profile_page.dart';
import 'package:starter/features/settings/settings_page.dart';
import 'package:starter/features/settings/settings_section.dart';
import 'package:starter/i18n/translations.g.dart';

void main() {
  test('case IDs are unique, stable, and screen-specific', () {
    final cases = buildProductionGalleryCases();
    final ids = cases.map((galleryCase) => galleryCase.id).toList();

    expect(ids, _expectedCaseIds);
    expect(ids.toSet(), hasLength(ids.length));
    expect(cases, hasLength(72));
  });

  test('screen groups contain the complete deterministic state matrix', () {
    final counts = <String, int>{};
    for (final galleryCase in buildProductionGalleryCases()) {
      counts.update(galleryCase.screenId, (count) => count + 1, ifAbsent: () => 1);
    }

    expect(counts, {
      'onboarding': 3,
      'paywall': 4,
      'pricing': 4,
      'home': 3,
      'login': 7,
      'register': 7,
      'forgot-password': 7,
      'reset-password': 7,
      'otp-registration': 9,
      'otp-password-reset': 9,
      'profile': 6,
      'settings': 6,
    });
  });

  for (final locale in AppLocale.values) {
    test('all labels are localized and non-empty for ${locale.languageTag}', () {
      final translations = locale.buildSync();

      for (final galleryCase in buildProductionGalleryCases()) {
        expect(galleryCase.screenLabel(translations), isNotEmpty, reason: galleryCase.id);
        expect(galleryCase.caseLabel(translations), isNotEmpty, reason: galleryCase.id);
      }
    });
  }

  testWidgets('typed states construct real production page types', (tester) async {
    final context = await _localizedContext(tester);
    final cases = buildProductionGalleryCases();

    final expectedTypes = <String, Type>{
      'onboarding': OnboardingPage,
      'paywall': PaywallPage,
      'pricing': PricingPage,
      'home': HomePage,
      'login': LoginPage,
      'register': RegisterPage,
      'forgot-password': ForgotPasswordPage,
      'reset-password': ResetPasswordPage,
      'otp-registration': OtpPage,
      'otp-password-reset': OtpPage,
      'profile': UpdateProfilePage,
      'settings': SettingsPage,
    };

    for (final galleryCase in cases) {
      expect(
        galleryCase.build(context).runtimeType,
        expectedTypes[galleryCase.screenId],
        reason: galleryCase.id,
      );
    }

    final onboarding =
        _caseById(cases, 'onboarding.final') as TypedGalleryCase<OnboardingGalleryState>;
    final onboardingState = onboarding.stateFactory(context);
    expect(onboardingState.initialPage, 2);
    expect(onboarding.pageFactory(context, onboardingState), isA<OnboardingPage>());

    final pricing =
        _caseById(cases, 'pricing.unavailable') as TypedGalleryCase<PricingGalleryState>;
    final pricingState = pricing.stateFactory(context);
    expect(pricingState.availability, PricingAvailability.unavailable);
    expect(
      pricingState.plans.every((plan) => plan.availability == pricingState.availability),
      isTrue,
    );
    expect(pricing.pageFactory(context, pricingState), isA<PricingPage>());

    final home = _caseById(cases, 'home.empty') as TypedGalleryCase<HomeViewData>;
    final homeState = home.stateFactory(context);
    expect(homeState.hasRecentActivity, isFalse);
    expect(home.pageFactory(context, homeState), isA<HomePage>());

    final expandedHome = _caseById(cases, 'home.expandedCopy') as TypedGalleryCase<HomeViewData>;
    expect(
      expandedHome.stateFactory(context).greetingName,
      'Alexandra-Montgomery-Watanabe-المنصوري',
    );

    final login =
        _caseById(cases, 'auth.login.globalError') as TypedGalleryCase<LoginPresentationState>;
    final loginState = login.stateFactory(context);
    expect(loginState.status, LoginPresentationStatus.globalFailure);
    expect(login.pageFactory(context, loginState), isA<LoginPage>());

    final otp =
        _caseById(cases, 'auth.otp.passwordReset.partial')
            as TypedGalleryCase<OtpPresentationState>;
    final otpState = otp.stateFactory(context);
    final otpPage = otp.pageFactory(context, otpState) as OtpPage;
    expect(otpState.status, OtpPresentationStatus.partial);
    expect(otpPage.purpose, OtpPurpose.passwordReset);

    final profile =
        _caseById(cases, 'profile.update.discardPrompt')
            as TypedGalleryCase<ProfilePresentationState>;
    final profileState = profile.stateFactory(context);
    expect(profileState.phase, ProfilePresentationPhase.discardPrompt);
    expect(profile.pageFactory(context, profileState), isA<UpdateProfilePage>());

    final settings = _caseById(cases, 'settings.privacy') as TypedGalleryCase<SettingsSection?>;
    final settingsState = settings.stateFactory(context);
    final settingsPage = settings.pageFactory(context, settingsState) as SettingsPage;
    expect(settingsState, SettingsSection.privacyAbout);
    expect(await settingsPage.loadBuildLabel(), context.t.common.notConnected);
  });

  testWidgets('factories are synchronous and introduce no timer or repository dependency', (
    tester,
  ) async {
    final context = await _localizedContext(tester);

    for (final galleryCase in buildProductionGalleryCases()) {
      expect(galleryCase.build(context), isA<Widget>(), reason: galleryCase.id);
    }

    final source = File(
      'lib/features/dev_gallery/cases/production_gallery_cases.dart',
    ).readAsStringSync();
    expect(source, isNot(contains('Future.delayed')));
    expect(source, isNot(contains('Timer(')));
    expect(source.toLowerCase(), isNot(contains('repository')));
    expect(source, isNot(contains('app_routes.dart')));
    expect(source, isNot(contains('go_router')));
    expect(source, isNot(contains('_noop')));
  });
}

GalleryCase _caseById(List<GalleryCase> cases, String id) {
  return cases.singleWhere((galleryCase) => galleryCase.id == id);
}

Future<BuildContext> _localizedContext(WidgetTester tester) async {
  LocaleSettings.setLocaleSync(AppLocale.en);
  late BuildContext localizedContext;
  await tester.pumpWidget(
    TranslationProvider(
      child: Builder(
        builder: (context) {
          localizedContext = context;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return localizedContext;
}

const _expectedCaseIds = [
  'onboarding.first',
  'onboarding.middle',
  'onboarding.final',
  'pricing.paywall.monthly',
  'pricing.paywall.annual',
  'pricing.paywall.recommended',
  'pricing.paywall.unavailable',
  'pricing.monthly',
  'pricing.annual',
  'pricing.recommended',
  'pricing.unavailable',
  'home.default',
  'home.empty',
  'home.expandedCopy',
  'auth.login.idle',
  'auth.login.focused',
  'auth.login.invalid',
  'auth.login.submitting',
  'auth.login.fieldError',
  'auth.login.globalError',
  'auth.login.success',
  'auth.register.idle',
  'auth.register.focused',
  'auth.register.invalid',
  'auth.register.submitting',
  'auth.register.fieldError',
  'auth.register.globalError',
  'auth.register.success',
  'auth.forgotPassword.idle',
  'auth.forgotPassword.focused',
  'auth.forgotPassword.invalid',
  'auth.forgotPassword.submitting',
  'auth.forgotPassword.fieldError',
  'auth.forgotPassword.globalError',
  'auth.forgotPassword.success',
  'auth.resetPassword.idle',
  'auth.resetPassword.focused',
  'auth.resetPassword.invalid',
  'auth.resetPassword.submitting',
  'auth.resetPassword.fieldError',
  'auth.resetPassword.globalError',
  'auth.resetPassword.success',
  'auth.otp.registration.empty',
  'auth.otp.registration.partial',
  'auth.otp.registration.pastedComplete',
  'auth.otp.registration.invalid',
  'auth.otp.registration.expired',
  'auth.otp.registration.resending',
  'auth.otp.registration.submitting',
  'auth.otp.registration.globalError',
  'auth.otp.registration.success',
  'auth.otp.passwordReset.empty',
  'auth.otp.passwordReset.partial',
  'auth.otp.passwordReset.pastedComplete',
  'auth.otp.passwordReset.invalid',
  'auth.otp.passwordReset.expired',
  'auth.otp.passwordReset.resending',
  'auth.otp.passwordReset.submitting',
  'auth.otp.passwordReset.globalError',
  'auth.otp.passwordReset.success',
  'profile.update.default',
  'profile.update.dirty',
  'profile.update.invalid',
  'profile.update.saving',
  'profile.update.saved',
  'profile.update.discardPrompt',
  'settings.overview',
  'settings.appearance',
  'settings.language',
  'settings.account',
  'settings.subscription',
  'settings.privacy',
];
