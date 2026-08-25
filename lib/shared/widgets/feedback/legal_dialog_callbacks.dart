import 'package:flutter/widgets.dart';

import 'package:starter/shared/widgets/feedback/app_information_dialog.dart';

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
