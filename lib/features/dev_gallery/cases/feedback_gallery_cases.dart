import 'package:flutter/widgets.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/features/feedback/feedback_presentation_state.dart';
import 'package:starter/features/feedback/feedback_sheet.dart';
import 'package:starter/i18n/translations.g.dart';

/// Builds the feedback-sheet gallery cases: the static fixtures for the
/// `drafting` / `submitting` / `failed` states plus the success swap. Mirrors
/// `mfa_otp_gallery_cases.dart`: a self-contained `build<Feature>GalleryCases()`
/// that the registry spreads in (see the manifest wiring note).
///
/// Cases embed [FeedbackSheetBody] directly (sheets are modal, so the gallery
/// renders the body in a card rather than triggering a real sheet — mirrors
/// `PermissionRationaleBody`). The callbacks are inert no-ops; the gallery
/// exercises the deterministic rendering path only (C2: never fakes a backend
/// action in the gallery).
///
/// Development-only: gated behind `config.developmentToolsEnabled` by the
/// registry caller. Never compiled into a production surface.
List<GalleryCase> buildFeedbackGalleryCases() {
  return const <GalleryCase>[
    TypedGalleryCase<FeedbackPresentationState>(
      id: 'feedback.drafting',
      screenId: 'feedback',
      screenLabelBuilder: _screenLabel,
      caseLabelBuilder: _caseDrafting,
      stateFactory: _drafting,
      pageFactory: _body,
    ),
    TypedGalleryCase<FeedbackPresentationState>(
      id: 'feedback.submitting',
      screenId: 'feedback',
      screenLabelBuilder: _screenLabel,
      caseLabelBuilder: _caseSubmitting,
      stateFactory: _submitting,
      pageFactory: _body,
    ),
    TypedGalleryCase<FeedbackPresentationState>(
      id: 'feedback.failed',
      screenId: 'feedback',
      screenLabelBuilder: _screenLabel,
      caseLabelBuilder: _caseFailed,
      stateFactory: _failed,
      pageFactory: _body,
    ),
    TypedGalleryCase<FeedbackPresentationState>(
      id: 'feedback.success',
      screenId: 'feedback',
      screenLabelBuilder: _screenLabel,
      caseLabelBuilder: _caseSuccess,
      stateFactory: _success,
      pageFactory: _body,
    ),
  ];
}

String _screenLabel(Translations t) => t.devGallery.screenFeedback;

String _caseDrafting(Translations t) => t.devGallery.caseFeedbackDrafting;
String _caseSubmitting(Translations t) => t.devGallery.caseFeedbackSubmitting;
String _caseFailed(Translations t) => t.devGallery.caseFeedbackFailed;
String _caseSuccess(Translations t) => t.devGallery.caseFeedbackSuccess;

FeedbackPresentationState _drafting(BuildContext _) => const FeedbackPresentationState.drafting();
FeedbackPresentationState _submitting(BuildContext _) =>
    const FeedbackPresentationState.submitting();
FeedbackPresentationState _failed(BuildContext _) => const FeedbackPresentationState.failed();
FeedbackPresentationState _success(BuildContext _) => const FeedbackPresentationState.success();

Widget _body(BuildContext context, FeedbackPresentationState state) {
  // The gallery exercises the STATIC presentation path (no controller /
  // transport), so submit + dismiss are inert no-ops. The honest "no backend"
  // copy lives in the real app wiring; the gallery only renders the
  // deterministic state. Pinned include-screenshot fixture value keeps the
  // toggle stable across rebuilds.
  return FeedbackSheetBody(
    presentation: state,
    onDismiss: () {},
    onAccepted: () {},
  );
}
