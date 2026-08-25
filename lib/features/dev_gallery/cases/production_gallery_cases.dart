import 'package:flutter/widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:starter/app/routing/otp_purpose.dart';
import 'package:starter/features/auth/forgot_password_page.dart';
import 'package:starter/features/auth/forgot_password_presentation_state.dart';
import 'package:starter/features/auth/login_page.dart';
import 'package:starter/features/auth/login_presentation_state.dart';
import 'package:starter/features/auth/otp_page.dart';
import 'package:starter/features/auth/otp_presentation_state.dart';
import 'package:starter/features/auth/register_page.dart';
import 'package:starter/features/auth/register_presentation_state.dart';
import 'package:starter/features/auth/reset_password_page.dart';
import 'package:starter/features/auth/reset_password_presentation_state.dart';
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
import 'package:starter/shared/widgets/feedback/app_information_dialog.dart';
import 'package:starter/shared/widgets/feedback/legal_dialog_callbacks.dart';

part 'production_gallery_cases.freezed.dart';

@freezed
abstract class OnboardingGalleryState with _$OnboardingGalleryState {
  const factory OnboardingGalleryState({required int initialPage}) = _OnboardingGalleryState;
}

@freezed
class PricingGalleryState with _$PricingGalleryState {
  PricingGalleryState({
    required Iterable<PlanViewData> plans,
    required this.billingPeriod,
    required this.initialPlanId,
    required this.availability,
  }) : plans = List.unmodifiable(plans);

  @override
  final List<PlanViewData> plans;
  @override
  final BillingPeriod billingPeriod;
  @override
  final String initialPlanId;
  @override
  final PricingAvailability availability;
}

List<GalleryCase> buildProductionGalleryCases() => [
  ..._buildOnboardingCases(),
  ..._buildPaywallCases(),
  ..._buildPricingCases(),
  ..._buildHomeCases(),
  ..._buildLoginCases(),
  ..._buildRegisterCases(),
  ..._buildForgotPasswordCases(),
  ..._buildResetPasswordCases(),
  ..._buildOtpCases(
    purpose: OtpPurpose.registration,
    idPrefix: 'auth.otp.registration',
    screenId: 'otp-registration',
    screenLabelBuilder: (translations) => translations.devGallery.screenOtpRegistration,
  ),
  ..._buildOtpCases(
    purpose: OtpPurpose.passwordReset,
    idPrefix: 'auth.otp.passwordReset',
    screenId: 'otp-password-reset',
    screenLabelBuilder: (translations) => translations.devGallery.screenOtpPasswordReset,
  ),
  ..._buildProfileCases(),
  ..._buildSettingsCases(),
];

List<GalleryCase> _buildOnboardingCases() {
  return buildTypedGalleryCases<OnboardingGalleryState>(
    idPrefix: 'onboarding',
    screenId: 'onboarding',
    screenLabelBuilder: (translations) => translations.devGallery.screenOnboarding,
    definitions: [
      (
        suffix: 'first',
        labelBuilder: (translations) => translations.devGallery.caseFirst,
        stateFactory: (_) => const OnboardingGalleryState(initialPage: 0),
      ),
      (
        suffix: 'middle',
        labelBuilder: (translations) => translations.devGallery.caseMiddle,
        stateFactory: (_) => const OnboardingGalleryState(initialPage: 1),
      ),
      (
        suffix: 'final',
        labelBuilder: (translations) => translations.devGallery.caseFinal,
        stateFactory: (_) => const OnboardingGalleryState(initialPage: 2),
      ),
    ],
    pageFactory: (context, state) => OnboardingPage(
      initialPage: state.initialPage,
      onSkip: () => _showUnavailableFeedback(context),
      onOpenPaywall: () => _showUnavailableFeedback(context),
    ),
  );
}

List<GalleryCase> _buildPaywallCases() {
  return buildTypedGalleryCases<PricingGalleryState>(
    idPrefix: 'pricing.paywall',
    screenId: 'paywall',
    screenLabelBuilder: (translations) => translations.devGallery.screenPaywall,
    definitions: _pricingDefinitions(),
    pageFactory: (context, state) {
      final legal = legalDialogCallbacks(
        context,
        termsTitle: context.t.pricing.terms,
        privacyTitle: context.t.pricing.privacy,
      );
      return PaywallPage(
        plans: state.plans,
        initialBillingPeriod: state.billingPeriod,
        initialPlanId: state.initialPlanId,
        availability: state.availability,
        onSkip: () => _showUnavailableFeedback(context),
        onContinue: (plan, _) => showAppInformationDialog(
          context,
          title: context.t.pricing.choosePlan(plan: plan.name),
          body: context.t.pricing.staticSuccess,
        ),
        onRestore: () => showAppInformationDialog(
          context,
          title: context.t.pricing.restore,
          body: context.t.common.notConnected,
        ),
        onOpenTerms: legal.onOpenTerms,
        onOpenPrivacy: legal.onOpenPrivacy,
      );
    },
  );
}

List<GalleryCase> _buildPricingCases() {
  return buildTypedGalleryCases<PricingGalleryState>(
    idPrefix: 'pricing',
    screenId: 'pricing',
    screenLabelBuilder: (translations) => translations.devGallery.screenPricing,
    definitions: _pricingDefinitions(),
    pageFactory: (context, state) {
      final legal = legalDialogCallbacks(
        context,
        termsTitle: context.t.pricing.terms,
        privacyTitle: context.t.pricing.privacy,
      );
      return PricingPage(
        plans: state.plans,
        initialBillingPeriod: state.billingPeriod,
        initialPlanId: state.initialPlanId,
        availability: state.availability,
        onSelectPlan: (plan, _) => showAppInformationDialog(
          context,
          title: context.t.pricing.choosePlan(plan: plan.name),
          body: context.t.pricing.staticPurchaseNotice,
        ),
        onOpenTerms: legal.onOpenTerms,
        onOpenPrivacy: legal.onOpenPrivacy,
      );
    },
  );
}

List<GalleryCaseDefinition<PricingGalleryState>> _pricingDefinitions() => [
  (
    suffix: 'monthly',
    labelBuilder: (translations) => translations.devGallery.caseMonthly,
    stateFactory: (context) => PricingGalleryState(
      plans: PricingFixtures.standard(context.t),
      billingPeriod: BillingPeriod.monthly,
      initialPlanId: PlanIds.basic,
      availability: PricingAvailability.available,
    ),
  ),
  (
    suffix: 'annual',
    labelBuilder: (translations) => translations.devGallery.caseAnnual,
    stateFactory: (context) => PricingGalleryState(
      plans: PricingFixtures.standard(context.t),
      billingPeriod: BillingPeriod.annual,
      initialPlanId: PlanIds.basic,
      availability: PricingAvailability.available,
    ),
  ),
  (
    suffix: 'recommended',
    labelBuilder: (translations) => translations.devGallery.caseRecommended,
    stateFactory: (context) => PricingGalleryState(
      plans: PricingFixtures.standard(context.t),
      billingPeriod: BillingPeriod.monthly,
      initialPlanId: PlanIds.pro,
      availability: PricingAvailability.available,
    ),
  ),
  (
    suffix: 'unavailable',
    labelBuilder: (translations) => translations.devGallery.caseUnavailable,
    stateFactory: (context) => PricingGalleryState(
      plans: PricingFixtures.unavailable(context.t),
      billingPeriod: BillingPeriod.annual,
      initialPlanId: PlanIds.pro,
      availability: PricingAvailability.unavailable,
    ),
  ),
];

List<GalleryCase> _buildHomeCases() {
  return buildTypedGalleryCases<HomeViewData>(
    idPrefix: 'home',
    screenId: 'home',
    screenLabelBuilder: (translations) => translations.devGallery.screenHome,
    definitions: [
      (
        suffix: 'default',
        labelBuilder: (translations) => translations.devGallery.caseDefault,
        stateFactory: (_) => HomeViewData.defaults(),
      ),
      (
        suffix: 'empty',
        labelBuilder: (translations) => translations.devGallery.caseEmpty,
        stateFactory: (_) => HomeViewData.emptyActivity(),
      ),
      (
        suffix: 'expandedCopy',
        labelBuilder: (translations) => translations.devGallery.caseExpandedCopy,
        stateFactory: (_) => HomeViewData.defaults(
          greetingName: 'Alexandra-Montgomery-Watanabe-المنصوري',
        ),
      ),
    ],
    pageFactory: (context, state) => HomePage(
      viewData: state,
      onOpenProfile: () => _showUnavailableFeedback(context),
      onOpenPricing: () => _showUnavailableFeedback(context),
      onOpenSettings: () => _showUnavailableFeedback(context),
      onOpenLogin: () => _showUnavailableFeedback(context),
    ),
  );
}

List<GalleryCase> _buildLoginCases() {
  return buildTypedGalleryCases<LoginPresentationState>(
    idPrefix: 'auth.login',
    screenId: 'login',
    screenLabelBuilder: (translations) => translations.devGallery.screenLogin,
    definitions: [
      galleryCaseOf('idle', _caseDefault, const LoginPresentationState()),
      galleryCaseOf('focused', _caseFocused, const LoginPresentationState.focused()),
      galleryCaseOf('invalid', _caseInvalid, const LoginPresentationState.invalid()),
      galleryCaseOf('submitting', _caseSubmitting, const LoginPresentationState.submitting()),
      galleryCaseOf('fieldError', _caseFieldError, const LoginPresentationState.fieldFailure()),
      galleryCaseOf('globalError', _caseGlobalError, const LoginPresentationState.globalFailure()),
      galleryCaseOf('success', _caseSuccess, const LoginPresentationState.success()),
    ],
    pageFactory: (context, state) => LoginPage(
      presentation: state,
      onSubmit: (_) => _showUnavailableFeedback(context),
      onForgotPassword: () => _showUnavailableFeedback(context),
      onRegister: () => _showUnavailableFeedback(context),
    ),
  );
}

List<GalleryCase> _buildRegisterCases() {
  return buildTypedGalleryCases<RegisterPresentationState>(
    idPrefix: 'auth.register',
    screenId: 'register',
    screenLabelBuilder: (translations) => translations.devGallery.screenRegister,
    definitions: [
      galleryCaseOf('idle', _caseDefault, const RegisterPresentationState()),
      galleryCaseOf('focused', _caseFocused, const RegisterPresentationState.focused()),
      galleryCaseOf('invalid', _caseInvalid, const RegisterPresentationState.invalid()),
      galleryCaseOf('submitting', _caseSubmitting, const RegisterPresentationState.submitting()),
      galleryCaseOf('fieldError', _caseFieldError, const RegisterPresentationState.fieldFailure()),
      galleryCaseOf(
        'globalError',
        _caseGlobalError,
        const RegisterPresentationState.globalFailure(),
      ),
      galleryCaseOf('success', _caseSuccess, const RegisterPresentationState.success()),
    ],
    pageFactory: (context, state) {
      final legal = legalDialogCallbacks(
        context,
        termsTitle: context.t.auth.register.terms,
        privacyTitle: context.t.auth.register.privacy,
      );
      return RegisterPage(
        presentation: state,
        onSubmit: (_) => _showUnavailableFeedback(context),
        onLogin: () => _showUnavailableFeedback(context),
        onOpenTerms: legal.onOpenTerms,
        onOpenPrivacy: legal.onOpenPrivacy,
      );
    },
  );
}

List<GalleryCase> _buildForgotPasswordCases() {
  return buildTypedGalleryCases<ForgotPasswordPresentationState>(
    idPrefix: 'auth.forgotPassword',
    screenId: 'forgot-password',
    screenLabelBuilder: (translations) => translations.devGallery.screenForgotPassword,
    definitions: [
      galleryCaseOf('idle', _caseDefault, const ForgotPasswordPresentationState()),
      galleryCaseOf(
        'focused',
        _caseFocused,
        const ForgotPasswordPresentationState.focused(),
      ),
      galleryCaseOf('invalid', _caseInvalid, const ForgotPasswordPresentationState.invalid()),
      galleryCaseOf(
        'submitting',
        _caseSubmitting,
        const ForgotPasswordPresentationState.submitting(),
      ),
      galleryCaseOf(
        'fieldError',
        _caseFieldError,
        const ForgotPasswordPresentationState.fieldFailure(),
      ),
      galleryCaseOf(
        'globalError',
        _caseGlobalError,
        const ForgotPasswordPresentationState.globalFailure(),
      ),
      galleryCaseOf('success', _caseSuccess, const ForgotPasswordPresentationState.success()),
    ],
    pageFactory: (context, state) => ForgotPasswordPage(
      presentation: state,
      onSubmit: (_) => _showUnavailableFeedback(context),
      onLogin: () => _showUnavailableFeedback(context),
    ),
  );
}

List<GalleryCase> _buildResetPasswordCases() {
  return buildTypedGalleryCases<ResetPasswordPresentationState>(
    idPrefix: 'auth.resetPassword',
    screenId: 'reset-password',
    screenLabelBuilder: (translations) => translations.devGallery.screenResetPassword,
    definitions: [
      galleryCaseOf('idle', _caseDefault, const ResetPasswordPresentationState()),
      galleryCaseOf(
        'focused',
        _caseFocused,
        const ResetPasswordPresentationState.focused(),
      ),
      galleryCaseOf('invalid', _caseInvalid, const ResetPasswordPresentationState.invalid()),
      galleryCaseOf(
        'submitting',
        _caseSubmitting,
        const ResetPasswordPresentationState.submitting(),
      ),
      galleryCaseOf(
        'fieldError',
        _caseFieldError,
        const ResetPasswordPresentationState.fieldFailure(),
      ),
      galleryCaseOf(
        'globalError',
        _caseGlobalError,
        const ResetPasswordPresentationState.globalFailure(),
      ),
      galleryCaseOf('success', _caseSuccess, const ResetPasswordPresentationState.success()),
    ],
    pageFactory: (context, state) => ResetPasswordPage(
      presentation: state,
      onSubmit: (_) => _showUnavailableFeedback(context),
      onLogin: () => _showUnavailableFeedback(context),
    ),
  );
}

List<GalleryCase> _buildOtpCases({
  required OtpPurpose purpose,
  required String idPrefix,
  required String screenId,
  required GalleryLabelBuilder screenLabelBuilder,
}) {
  return buildTypedGalleryCases<OtpPresentationState>(
    idPrefix: idPrefix,
    screenId: screenId,
    screenLabelBuilder: screenLabelBuilder,
    definitions: [
      galleryCaseOf('empty', _caseEmpty, const OtpPresentationState()),
      galleryCaseOf('partial', _casePartial, const OtpPresentationState.partial()),
      galleryCaseOf(
        'pastedComplete',
        _casePastedComplete,
        const OtpPresentationState.pastedComplete(),
      ),
      galleryCaseOf('invalid', _caseInvalid, const OtpPresentationState.invalid()),
      galleryCaseOf('expired', _caseExpired, const OtpPresentationState.expired()),
      galleryCaseOf('resending', _caseResending, const OtpPresentationState.resending()),
      galleryCaseOf('submitting', _caseSubmitting, const OtpPresentationState.submitting()),
      galleryCaseOf('globalError', _caseGlobalError, const OtpPresentationState.globalFailure()),
      galleryCaseOf('success', _caseSuccess, const OtpPresentationState.success()),
    ],
    pageFactory: (context, state) => OtpPage(
      purpose: purpose,
      presentation: state,
      onSubmit: (_) => _showUnavailableFeedback(context),
      onResend: () => _showUnavailableFeedback(context),
    ),
  );
}

List<GalleryCase> _buildProfileCases() {
  return buildTypedGalleryCases<ProfilePresentationState>(
    idPrefix: 'profile.update',
    screenId: 'profile',
    screenLabelBuilder: (translations) => translations.devGallery.screenProfile,
    definitions: [
      galleryCaseOf(
        'default',
        _caseDefault,
        const ProfilePresentationState.defaults(),
      ),
      (
        suffix: 'dirty',
        labelBuilder: _caseDirty,
        stateFactory: (_) => ProfilePresentationState.dirty(draft: _dirtyProfileDraft()),
      ),
      (
        suffix: 'invalid',
        labelBuilder: _caseInvalid,
        stateFactory: (_) => ProfilePresentationState.invalid(draft: _invalidProfileDraft()),
      ),
      galleryCaseOf(
        'saving',
        _caseSaving,
        const ProfilePresentationState.saving(draft: ProfileDraft.defaults()),
      ),
      galleryCaseOf(
        'saved',
        _caseSaved,
        const ProfilePresentationState.saved(draft: ProfileDraft.defaults()),
      ),
      (
        suffix: 'discardPrompt',
        labelBuilder: _caseDiscardPrompt,
        stateFactory: (_) => ProfilePresentationState.discardPrompt(
          draft: _dirtyProfileDraft(),
        ),
      ),
    ],
    pageFactory: (context, state) => UpdateProfilePage(
      initialDraft: const ProfileDraft.defaults(),
      presentationState: state,
      onSave: (_) => _showUnavailableFeedback(context),
      onAvatarPicked: (_) => showAppInformationDialog(
        context,
        title: context.t.profile.update.changeAvatar,
        body: context.t.profile.update.avatarUnavailable,
      ),
    ),
  );
}

List<GalleryCase> _buildSettingsCases() {
  return buildTypedGalleryCases<SettingsSection?>(
    idPrefix: 'settings',
    screenId: 'settings',
    screenLabelBuilder: (translations) => translations.devGallery.screenSettings,
    definitions: [
      (
        suffix: 'overview',
        labelBuilder: _caseDefault,
        stateFactory: (_) => null,
      ),
      (
        suffix: 'appearance',
        labelBuilder: (translations) => translations.settings.appearance,
        stateFactory: (_) => SettingsSection.appearance,
      ),
      (
        suffix: 'language',
        labelBuilder: (translations) => translations.settings.language,
        stateFactory: (_) => SettingsSection.language,
      ),
      (
        suffix: 'account',
        labelBuilder: (translations) => translations.settings.account,
        stateFactory: (_) => SettingsSection.account,
      ),
      (
        suffix: 'subscription',
        labelBuilder: (translations) => translations.settings.subscription,
        stateFactory: (_) => SettingsSection.subscription,
      ),
      (
        suffix: 'privacy',
        labelBuilder: (translations) => translations.settings.privacyAbout,
        stateFactory: (_) => SettingsSection.privacyAbout,
      ),
    ],
    pageFactory: (context, state) {
      final legal = legalDialogCallbacks(
        context,
        termsTitle: context.t.settings.terms,
        privacyTitle: context.t.settings.privacy,
      );
      return SettingsPage(
        section: state,
        onOpenAppearance: () => _showUnavailableFeedback(context),
        onOpenLanguage: () => _showUnavailableFeedback(context),
        onOpenAccessibility: () => _showUnavailableFeedback(context),
        onOpenAccount: () => _showUnavailableFeedback(context),
        onOpenSubscription: () => _showUnavailableFeedback(context),
        onOpenPrivacyAbout: () => _showUnavailableFeedback(context),
        onOpenProfile: () => _showUnavailableFeedback(context),
        onOpenLogin: () => _showUnavailableFeedback(context),
        onOpenPricing: () => _showUnavailableFeedback(context),
        onOpenPasscodeSetup: () => _showUnavailableFeedback(context),
        onOpenTerms: legal.onOpenTerms,
        onOpenPrivacy: legal.onOpenPrivacy,
        onOpenLicense: () => showAppInformationDialog(
          context,
          title: context.t.settings.about.license,
        ),
        loadBuildLabel: () => Future.value(context.t.common.notConnected),
      );
    },
  );
}

ProfileDraft _dirtyProfileDraft() {
  return const ProfileDraft.defaults().copyWith(bio: '');
}

ProfileDraft _invalidProfileDraft() {
  return const ProfileDraft.defaults().copyWith(username: '');
}

void _showUnavailableFeedback(BuildContext context) {
  showAppInformationDialog(
    context,
    title: context.t.common.legalPlaceholderTitle,
    body: context.t.common.notConnected,
  );
}

String _caseDefault(Translations translations) => translations.devGallery.caseDefault;
String _caseFocused(Translations translations) => translations.devGallery.caseFocused;
String _caseEmpty(Translations translations) => translations.devGallery.caseEmpty;
String _caseInvalid(Translations translations) => translations.devGallery.caseInvalid;
String _caseSubmitting(Translations translations) => translations.devGallery.caseSubmitting;
String _caseFieldError(Translations translations) => translations.devGallery.caseFieldError;
String _caseGlobalError(Translations translations) => translations.devGallery.caseGlobalError;
String _caseSuccess(Translations translations) => translations.devGallery.caseSuccess;
String _casePartial(Translations translations) => translations.devGallery.casePartial;
String _casePastedComplete(Translations translations) => translations.devGallery.casePastedComplete;
String _caseExpired(Translations translations) => translations.devGallery.caseExpired;
String _caseResending(Translations translations) => translations.devGallery.caseResending;
String _caseSaving(Translations translations) => translations.devGallery.caseSaving;
String _caseSaved(Translations translations) => translations.devGallery.caseSaved;
String _caseDirty(Translations translations) => translations.devGallery.caseDirty;
String _caseDiscardPrompt(Translations translations) => translations.devGallery.caseDiscardPrompt;
