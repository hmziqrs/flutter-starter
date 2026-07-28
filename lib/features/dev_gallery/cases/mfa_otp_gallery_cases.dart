import 'package:flutter/widgets.dart';
import 'package:starter/app/routing/otp_purpose.dart';
import 'package:starter/features/auth/otp_page.dart';
import 'package:starter/features/auth/otp_presentation_state.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/i18n/translations.g.dart';

/// Builds the MFA / OTP gallery cases for the `mfa` purpose: the static
/// fixtures the existing `_buildOtpCases` already covers for `registration` and
/// `password-reset`, plus the two states this feature deepens — a **live
/// countdown** (pinned to a deterministic `remainingSeconds` so the golden is
/// wall-clock-stable) and the **locked** handoff from auth-ratelimit.
///
/// Mirrors `connectivity_gallery_cases.dart`: a self-contained
/// `build<Feature>GalleryCases()` that the registry spreads in (see the
/// manifest wiring note). Cases use the existing static `OtpPresentationState`
/// fixtures (no timers, no repository, no persistence) — the countdown value is
/// a pinned field, not a running `Timer`, so the dev-gallery stays deterministic
/// (guardrail 10 / golden determinism).
///
/// Development-only: gated behind `config.developmentToolsEnabled` by the
/// registry caller. Never compiled into a production surface.
List<GalleryCase> buildMfaOtpGalleryCases() {
  return const <GalleryCase>[
    TypedGalleryCase<OtpPresentationState>(
      id: 'auth.otp.mfa.idle',
      screenId: 'otp-mfa',
      screenLabelBuilder: _screenLabel,
      caseLabelBuilder: _caseDefault,
      stateFactory: _idle,
      pageFactory: _mfaPage,
    ),
    TypedGalleryCase<OtpPresentationState>(
      id: 'auth.otp.mfa.countdown',
      screenId: 'otp-mfa',
      screenLabelBuilder: _screenLabel,
      caseLabelBuilder: _caseCountdown,
      // Pinned countdown — the golden fixture value (no FakeAsync / Timer). The
      // `countdown` constructor + `remainingSeconds` field are added by the
      // described otp_presentation_state.dart edit; this is the one gallery
      // reference that resolves when that edit lands.
      stateFactory: _countdown,
      pageFactory: _mfaPage,
    ),
    TypedGalleryCase<OtpPresentationState>(
      id: 'auth.otp.mfa.invalid',
      screenId: 'otp-mfa',
      screenLabelBuilder: _screenLabel,
      caseLabelBuilder: _caseInvalid,
      stateFactory: _invalid,
      pageFactory: _mfaPage,
    ),
    TypedGalleryCase<OtpPresentationState>(
      id: 'auth.otp.mfa.expired',
      screenId: 'otp-mfa',
      screenLabelBuilder: _screenLabel,
      caseLabelBuilder: _caseExpired,
      stateFactory: _expired,
      pageFactory: _mfaPage,
    ),
    TypedGalleryCase<OtpPresentationState>(
      id: 'auth.otp.mfa.locked',
      screenId: 'otp-mfa',
      screenLabelBuilder: _screenLabel,
      caseLabelBuilder: _caseLocked,
      // Locked handoff from auth-ratelimit: the static fixture carries the
      // cooldown seconds the page decrements. Reuses the existing `.locked`
      // constructor (no duplication of lockout state, per the spec).
      stateFactory: _locked,
      pageFactory: _mfaPage,
    ),
    TypedGalleryCase<OtpPresentationState>(
      id: 'auth.otp.mfa.resending',
      screenId: 'otp-mfa',
      screenLabelBuilder: _screenLabel,
      caseLabelBuilder: _caseResending,
      stateFactory: _resending,
      pageFactory: _mfaPage,
    ),
    TypedGalleryCase<OtpPresentationState>(
      id: 'auth.otp.mfa.submitting',
      screenId: 'otp-mfa',
      screenLabelBuilder: _screenLabel,
      caseLabelBuilder: _caseSubmitting,
      stateFactory: _submitting,
      pageFactory: _mfaPage,
    ),
    TypedGalleryCase<OtpPresentationState>(
      id: 'auth.otp.mfa.globalError',
      screenId: 'otp-mfa',
      screenLabelBuilder: _screenLabel,
      caseLabelBuilder: _caseGlobalError,
      stateFactory: _globalError,
      pageFactory: _mfaPage,
    ),
    TypedGalleryCase<OtpPresentationState>(
      id: 'auth.otp.mfa.success',
      screenId: 'otp-mfa',
      screenLabelBuilder: _screenLabel,
      caseLabelBuilder: _caseSuccess,
      stateFactory: _success,
      pageFactory: _mfaPage,
    ),
  ];
}

String _screenLabel(Translations t) => t.devGallery.screenOtpMfa;

String _caseDefault(Translations t) => t.devGallery.caseDefault;
String _caseCountdown(Translations t) => t.devGallery.caseCountdown;
String _caseInvalid(Translations t) => t.devGallery.caseInvalid;
String _caseExpired(Translations t) => t.devGallery.caseExpired;
String _caseLocked(Translations t) => t.devGallery.caseLocked;
String _caseResending(Translations t) => t.devGallery.caseResending;
String _caseSubmitting(Translations t) => t.devGallery.caseSubmitting;
String _caseGlobalError(Translations t) => t.devGallery.caseGlobalError;
String _caseSuccess(Translations t) => t.devGallery.caseSuccess;

OtpPresentationState _idle(BuildContext _) => const OtpPresentationState();
OtpPresentationState _countdown(BuildContext _) =>
    const OtpPresentationState.countdown(remainingSeconds: 42);
OtpPresentationState _invalid(BuildContext _) => const OtpPresentationState.invalid();
OtpPresentationState _expired(BuildContext _) => const OtpPresentationState.expired();
OtpPresentationState _locked(BuildContext _) =>
    const OtpPresentationState.locked(lockedSeconds: 30);
OtpPresentationState _resending(BuildContext _) => const OtpPresentationState.resending();
OtpPresentationState _submitting(BuildContext _) => const OtpPresentationState.submitting();
OtpPresentationState _globalError(BuildContext _) => const OtpPresentationState.globalFailure();
OtpPresentationState _success(BuildContext _) => const OtpPresentationState.success();

OtpPage _mfaPage(BuildContext _, OtpPresentationState state) {
  // The gallery exercises the STATIC presentation path (no controller / repo),
  // so submit + resend are inert — a dev preview surface, not an action path.
  // The honest "no backend" feedback lives in the real app_router wiring; the
  // gallery only renders the deterministic state.
  return OtpPage(
    purpose: OtpPurpose.mfa,
    presentation: state,
    onSubmit: (_) {},
    onResend: () {},
  );
}
