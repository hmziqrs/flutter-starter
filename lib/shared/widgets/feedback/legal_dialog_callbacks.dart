import 'package:flutter/widgets.dart';

import 'package:starter/shared/widgets/feedback/app_information_dialog.dart';

/// Builds the matched terms/privacy open callbacks for a routed screen.
///
/// Both callbacks surface [showAppInformationDialog]; the dialog body falls back
/// to the shared legal placeholder body, matching the inline pairs that previously
/// lived in each feature route module. Capturing [context] here mirrors the prior
/// `() => showAppInformationDialog(context, ...)` closures.
({VoidCallback onOpenTerms, VoidCallback onOpenPrivacy}) legalDialogCallbacks(
  BuildContext context, {
  required String termsTitle,
  required String privacyTitle,
}) {
  return (
    onOpenTerms: () => showAppInformationDialog(context, title: termsTitle),
    onOpenPrivacy: () => showAppInformationDialog(context, title: privacyTitle),
  );
}
