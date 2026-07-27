import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/app/presentation/production_page_factory.dart';
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
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/escape_dismissible_overlay.dart';

@immutable
final class OnboardingGalleryState {
  const OnboardingGalleryState({required this.initialPage});

  final int initialPage;
}

@immutable
final class PricingGalleryState {
  PricingGalleryState({
    required Iterable<PlanViewData> plans,
    required this.billingPeriod,
    required this.initialPlanId,
    required this.availability,
  }) : plans = List.unmodifiable(plans);

  final List<PlanViewData> plans;
  final BillingPeriod billingPeriod;
  final String initialPlanId;
  final PricingAvailability availability;
}

typedef _CaseDefinition<TState> = ({
  String suffix,
  GalleryLabelBuilder labelBuilder,
  GalleryStateFactory<TState> stateFactory,
});

/// Builds every production-page case contributed by the static feature wave.
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
  return _typedCases<OnboardingGalleryState>(
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
  return _typedCases<PricingGalleryState>(
    idPrefix: 'pricing.paywall',
    screenId: 'paywall',
    screenLabelBuilder: (translations) => translations.devGallery.screenPaywall,
    definitions: _pricingDefinitions(),
    pageFactory: (context, state) => PaywallPage(
      plans: state.plans,
      initialBillingPeriod: state.billingPeriod,
      initialPlanId: state.initialPlanId,
      availability: state.availability,
      onSkip: () => _showUnavailableFeedback(context),
      onContinue: (plan, _) => _showInformationDialog(
        context,
        title: context.t.pricing.choosePlan(plan: plan.name),
        body: context.t.pricing.staticSuccess,
      ),
      onRestore: () => _showInformationDialog(
        context,
        title: context.t.pricing.restore,
        body: context.t.common.notConnected,
      ),
      onOpenTerms: () => _showLegalDialog(context, context.t.pricing.terms),
      onOpenPrivacy: () => _showLegalDialog(context, context.t.pricing.privacy),
    ),
  );
}

List<GalleryCase> _buildPricingCases() {
  return _typedCases<PricingGalleryState>(
    idPrefix: 'pricing',
    screenId: 'pricing',
    screenLabelBuilder: (translations) => translations.devGallery.screenPricing,
    definitions: _pricingDefinitions(),
    pageFactory: (context, state) => PricingPage(
      plans: state.plans,
      initialBillingPeriod: state.billingPeriod,
      initialPlanId: state.initialPlanId,
      availability: state.availability,
      onSelectPlan: (plan, _) => _showInformationDialog(
        context,
        title: context.t.pricing.choosePlan(plan: plan.name),
        body: context.t.pricing.staticPurchaseNotice,
      ),
      onOpenTerms: () => _showLegalDialog(context, context.t.pricing.terms),
      onOpenPrivacy: () => _showLegalDialog(context, context.t.pricing.privacy),
    ),
  );
}

List<_CaseDefinition<PricingGalleryState>> _pricingDefinitions() => [
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
  return _typedCases<HomeViewData>(
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
  return _typedCases<LoginPresentationState>(
    idPrefix: 'auth.login',
    screenId: 'login',
    screenLabelBuilder: (translations) => translations.devGallery.screenLogin,
    definitions: [
      _definition('idle', _caseDefault, const LoginPresentationState()),
      _definition('focused', _caseFocused, const LoginPresentationState.focused()),
      _definition('invalid', _caseInvalid, const LoginPresentationState.invalid()),
      _definition('submitting', _caseSubmitting, const LoginPresentationState.submitting()),
      _definition('fieldError', _caseFieldError, const LoginPresentationState.fieldFailure()),
      _definition('globalError', _caseGlobalError, const LoginPresentationState.globalFailure()),
      _definition('success', _caseSuccess, const LoginPresentationState.success()),
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
  return _typedCases<RegisterPresentationState>(
    idPrefix: 'auth.register',
    screenId: 'register',
    screenLabelBuilder: (translations) => translations.devGallery.screenRegister,
    definitions: [
      _definition('idle', _caseDefault, const RegisterPresentationState()),
      _definition('focused', _caseFocused, const RegisterPresentationState.focused()),
      _definition('invalid', _caseInvalid, const RegisterPresentationState.invalid()),
      _definition('submitting', _caseSubmitting, const RegisterPresentationState.submitting()),
      _definition('fieldError', _caseFieldError, const RegisterPresentationState.fieldFailure()),
      _definition(
        'globalError',
        _caseGlobalError,
        const RegisterPresentationState.globalFailure(),
      ),
      _definition('success', _caseSuccess, const RegisterPresentationState.success()),
    ],
    pageFactory: (context, state) => RegisterPage(
      presentation: state,
      onSubmit: (_) => _showUnavailableFeedback(context),
      onLogin: () => _showUnavailableFeedback(context),
      onOpenTerms: () => _showLegalDialog(context, context.t.auth.register.terms),
      onOpenPrivacy: () => _showLegalDialog(context, context.t.auth.register.privacy),
    ),
  );
}

List<GalleryCase> _buildForgotPasswordCases() {
  return _typedCases<ForgotPasswordPresentationState>(
    idPrefix: 'auth.forgotPassword',
    screenId: 'forgot-password',
    screenLabelBuilder: (translations) => translations.devGallery.screenForgotPassword,
    definitions: [
      _definition('idle', _caseDefault, const ForgotPasswordPresentationState()),
      _definition(
        'focused',
        _caseFocused,
        const ForgotPasswordPresentationState.focused(),
      ),
      _definition('invalid', _caseInvalid, const ForgotPasswordPresentationState.invalid()),
      _definition(
        'submitting',
        _caseSubmitting,
        const ForgotPasswordPresentationState.submitting(),
      ),
      _definition(
        'fieldError',
        _caseFieldError,
        const ForgotPasswordPresentationState.fieldFailure(),
      ),
      _definition(
        'globalError',
        _caseGlobalError,
        const ForgotPasswordPresentationState.globalFailure(),
      ),
      _definition('success', _caseSuccess, const ForgotPasswordPresentationState.success()),
    ],
    pageFactory: (context, state) => ForgotPasswordPage(
      presentation: state,
      onSubmit: (_) => _showUnavailableFeedback(context),
      onLogin: () => _showUnavailableFeedback(context),
    ),
  );
}

List<GalleryCase> _buildResetPasswordCases() {
  return _typedCases<ResetPasswordPresentationState>(
    idPrefix: 'auth.resetPassword',
    screenId: 'reset-password',
    screenLabelBuilder: (translations) => translations.devGallery.screenResetPassword,
    definitions: [
      _definition('idle', _caseDefault, const ResetPasswordPresentationState()),
      _definition(
        'focused',
        _caseFocused,
        const ResetPasswordPresentationState.focused(),
      ),
      _definition('invalid', _caseInvalid, const ResetPasswordPresentationState.invalid()),
      _definition(
        'submitting',
        _caseSubmitting,
        const ResetPasswordPresentationState.submitting(),
      ),
      _definition(
        'fieldError',
        _caseFieldError,
        const ResetPasswordPresentationState.fieldFailure(),
      ),
      _definition(
        'globalError',
        _caseGlobalError,
        const ResetPasswordPresentationState.globalFailure(),
      ),
      _definition('success', _caseSuccess, const ResetPasswordPresentationState.success()),
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
  return _typedCases<OtpPresentationState>(
    idPrefix: idPrefix,
    screenId: screenId,
    screenLabelBuilder: screenLabelBuilder,
    definitions: [
      _definition('empty', _caseEmpty, const OtpPresentationState()),
      _definition('partial', _casePartial, const OtpPresentationState.partial()),
      _definition(
        'pastedComplete',
        _casePastedComplete,
        const OtpPresentationState.pastedComplete(),
      ),
      _definition('invalid', _caseInvalid, const OtpPresentationState.invalid()),
      _definition('expired', _caseExpired, const OtpPresentationState.expired()),
      _definition('resending', _caseResending, const OtpPresentationState.resending()),
      _definition('submitting', _caseSubmitting, const OtpPresentationState.submitting()),
      _definition('globalError', _caseGlobalError, const OtpPresentationState.globalFailure()),
      _definition('success', _caseSuccess, const OtpPresentationState.success()),
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
  return _typedCases<ProfilePresentationState>(
    idPrefix: 'profile.update',
    screenId: 'profile',
    screenLabelBuilder: (translations) => translations.devGallery.screenProfile,
    definitions: [
      _definition(
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
      _definition(
        'saving',
        _caseSaving,
        const ProfilePresentationState.saving(draft: ProfileDraft.defaults()),
      ),
      _definition(
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
      onAvatarFeedback: () => _showInformationDialog(
        context,
        title: context.t.profile.update.changeAvatar,
        body: context.t.profile.update.avatarUnavailable,
      ),
    ),
  );
}

List<GalleryCase> _buildSettingsCases() {
  return _typedCases<SettingsSection?>(
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
    pageFactory: (context, state) => SettingsPage(
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
      onOpenTerms: () => _showLegalDialog(context, context.t.settings.terms),
      onOpenPrivacy: () => _showLegalDialog(context, context.t.settings.privacy),
      loadBuildLabel: () => Future.value(context.t.common.notConnected),
    ),
  );
}

List<GalleryCase> _typedCases<TState>({
  required String idPrefix,
  required String screenId,
  required GalleryLabelBuilder screenLabelBuilder,
  required List<_CaseDefinition<TState>> definitions,
  required ProductionPageFactory<TState> pageFactory,
}) {
  return [
    for (final definition in definitions)
      TypedGalleryCase<TState>(
        id: '$idPrefix.${definition.suffix}',
        screenId: screenId,
        screenLabelBuilder: screenLabelBuilder,
        caseLabelBuilder: definition.labelBuilder,
        stateFactory: definition.stateFactory,
        pageFactory: pageFactory,
      ),
  ];
}

_CaseDefinition<TState> _definition<TState>(
  String suffix,
  GalleryLabelBuilder labelBuilder,
  TState state,
) {
  return (
    suffix: suffix,
    labelBuilder: labelBuilder,
    stateFactory: (_) => state,
  );
}

ProfileDraft _dirtyProfileDraft() {
  return const ProfileDraft.defaults().copyWith(bio: '');
}

ProfileDraft _invalidProfileDraft() {
  return const ProfileDraft.defaults().copyWith(username: '');
}

void _showLegalDialog(BuildContext context, String title) {
  _showInformationDialog(
    context,
    title: title,
    body: context.t.common.legalPlaceholderBody,
  );
}

void _showUnavailableFeedback(BuildContext context) {
  _showInformationDialog(
    context,
    title: context.t.common.legalPlaceholderTitle,
    body: context.t.common.notConnected,
  );
}

void _showInformationDialog(
  BuildContext context, {
  required String title,
  required String body,
}) {
  unawaited(
    showFDialog<void>(
      context: context,
      useSafeArea: true,
      builder: (context, style, animation) => EscapeDismissibleOverlay(
        child: FDialog(
          animation: animation,
          semanticsLabel: title,
          builder: (context, style) => Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: style.titleTextStyle),
                const SizedBox(height: AppSpacing.md),
                Text(body, style: style.bodyTextStyle),
                const SizedBox(height: AppSpacing.xl),
                FButton(
                  onPress: () => Navigator.of(context).pop(),
                  child: Text(context.t.common.close),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
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
