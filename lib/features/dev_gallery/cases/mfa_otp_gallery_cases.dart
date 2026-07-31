import 'package:starter/app/routing/otp_purpose.dart';
import 'package:starter/features/auth/otp_page.dart';
import 'package:starter/features/auth/otp_presentation_state.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';

List<GalleryCase> buildMfaOtpGalleryCases() {
  return buildTypedGalleryCases<OtpPresentationState>(
    idPrefix: 'auth.otp.mfa',
    screenId: 'otp-mfa',
    screenLabelBuilder: (t) => t.devGallery.screenOtpMfa,
    definitions: [
      galleryCaseOf('idle', (t) => t.devGallery.caseDefault, const OtpPresentationState()),
      galleryCaseOf(
        'countdown',
        (t) => t.devGallery.caseCountdown,
        const OtpPresentationState.countdown(remainingSeconds: 42),
      ),
      galleryCaseOf(
        'invalid',
        (t) => t.devGallery.caseInvalid,
        const OtpPresentationState.invalid(),
      ),
      galleryCaseOf(
        'expired',
        (t) => t.devGallery.caseExpired,
        const OtpPresentationState.expired(),
      ),
      galleryCaseOf(
        'locked',
        (t) => t.devGallery.caseLocked,
        const OtpPresentationState.locked(lockedSeconds: 30),
      ),
      galleryCaseOf(
        'resending',
        (t) => t.devGallery.caseResending,
        const OtpPresentationState.resending(),
      ),
      galleryCaseOf(
        'submitting',
        (t) => t.devGallery.caseSubmitting,
        const OtpPresentationState.submitting(),
      ),
      galleryCaseOf(
        'globalError',
        (t) => t.devGallery.caseGlobalError,
        const OtpPresentationState.globalFailure(),
      ),
      galleryCaseOf(
        'success',
        (t) => t.devGallery.caseSuccess,
        const OtpPresentationState.success(),
      ),
    ],
    pageFactory: (context, state) => OtpPage(
      purpose: OtpPurpose.mfa,
      presentation: state,
      onSubmit: (_) {},
      onResend: () {},
    ),
  );
}
