# Static feature implementation contracts

This file freezes the M4 boundaries used by the M5 dynamic-agent wave. The route table,
translations, shared tokens, dependencies, and app composition remain root-owned while agents
work in disjoint feature directories.

## Shared rules

- Features may import `app/routing/otp_purpose.dart`, generated translations, and existing
  `shared/**` APIs. They must not import another feature, route constants, the gallery, or plugin
  adapters.
- Pages receive navigation and deterministic feedback callbacks. They never call `go_router`
  directly.
- Every form uses Flutter `Form`/`FormField` with native ForUI controls, constructs a handwritten
  typed value after validation/save, and never trims passwords or OTP values.
- Presentation fixtures are feature-owned, immutable, and screen-specific. Normal route usage
  defaults to idle. No fixture uses timers, repositories, fake authentication, or persistence.
- State names use the smallest relevant vocabulary: `idle`, `submitting`, `fieldFailure`,
  `globalFailure`, and `success`; OTP adds `partial`, `invalid`, `expired`, and `resending`; Profile
  adds `dirty`, `saving`, `saved`, and `discardPrompt`; Pricing adds `available` and `unavailable`.
- Public page/view-data constructors remain usable by `ProductionPageFactory<TState>` adapters.

## Auth (`features/auth/**`)

Public typed values: `LoginFormValue`, `RegisterFormValue`, `ForgotPasswordFormValue`,
`OtpFormValue`, and `ResetPasswordFormValue`.

Public pages and required callbacks:

- `LoginPage`: `onSubmit(LoginFormValue)`, `onForgotPassword`, `onRegister`.
- `RegisterPage`: `onSubmit(RegisterFormValue)`, `onLogin`, `onOpenTerms`, `onOpenPrivacy`.
- `ForgotPasswordPage`: `onSubmit(ForgotPasswordFormValue)`, `onLogin`.
- `OtpPage`: typed `OtpPurpose`, `onSubmit(OtpFormValue)`, `onResend`.
- `ResetPasswordPage`: `onSubmit(ResetPasswordFormValue)`, `onLogin`.

Login and Register are implemented and compared first. Only then may repeated focus/reveal,
checkbox, or validator mechanics move to `shared/forms/**`, and only through a root-owned follow-up
task that explicitly transfers those paths.

## Pricing and onboarding

Pricing owns `BillingPeriod`, stable plan IDs, `PlanViewData`, plan selection, and shared plan
widgets. Prices are numeric values formatted with `intl`; translated files contain labels and
benefits, never preformatted currency strings.

- `PricingPage`: `onSelectPlan`, `onOpenTerms`, and `onOpenPrivacy`; typed initial billing and
  availability state.
- `PaywallPage`: `onSkip`, `onContinue`, `onRestore`, `onOpenTerms`, and `onOpenPrivacy`; Skip is
  always visible and the static CTA never implies a purchase.
- `OnboardingPage`: `onSkip` and `onOpenPaywall`; typed/validated `initialPage` from 0 through 2;
  page index stays local and survives width-only rebuilds.

## Home and profile

- `HomeViewData` contains immutable greeting/status/activity content and an explicit empty-activity
  variant; it does not create a repository.
- `HomePage` receives `onOpenProfile`, `onOpenPricing`, `onOpenSettings`, and `onOpenLogin`.
- `ProfileDraft` and `ProfilePresentationState` are immutable. `UpdateProfilePage` receives typed
  initial data, `onSave(ProfileDraft)`, and `onAvatarFeedback`.
- Profile email is read-only, image actions never request permission, Bio is multiline and
  grapheme-aware, Enter never submits from Bio, and dirty Back shows a discard confirmation.

## Root integration sequence

1. Integrate Login/Register and decide whether two proven form mechanics earn extraction.
2. Follow up with the Auth agent for Forgot Password, OTP, and Reset Password.
3. Integrate Pricing/Onboarding and Home/Profile public APIs.
4. Replace every temporary router placeholder with a production page and route-owned callbacks.
5. Run direct-location, typed OTP, navigation-flow, responsive-state, locale, format, analysis,
   generation-drift, and complete test gates.
