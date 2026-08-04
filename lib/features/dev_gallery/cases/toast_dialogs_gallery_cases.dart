import 'dart:async';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/feedback/app_confirmation_dialog.dart';
import 'package:starter/shared/widgets/feedback/app_toast.dart';

enum ToastDialogGalleryKind {
  toastSuccess,
  toastInfo,
  toastWarning,
  toastError,
  dialogConfirm,
  dialogDestroy,
}

List<GalleryCase> buildToastDialogsGalleryCases() {
  return ToastDialogGalleryKind.values
      .map(
        (kind) => TypedGalleryCase<ToastDialogGalleryKind>(
          id: 'toastDialogs.${kind.name}',
          screenId: 'toastDialogs',
          screenLabelBuilder: (translations) => translations.devGallery.screenToastDialogs,
          caseLabelBuilder: (translations) => _caseLabel(translations, kind),
          stateFactory: (_) => kind,
          pageFactory: (_, state) => _ToastDialogPreview(kind: state),
        ),
      )
      .toList(growable: false);
}

class _ToastDialogPreview extends StatelessWidget {
  const _ToastDialogPreview({required this.kind});

  final ToastDialogGalleryKind kind;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: FButton(
          key: ValueKey<String>('toast-dialog-trigger-${kind.name}'),
          onPress: () => _activate(context),
          child: Text(_caseLabel(translations, kind)),
        ),
      ),
    );
  }

  void _activate(BuildContext context) {
    final translations = context.t;
    switch (kind) {
      case ToastDialogGalleryKind.toastSuccess:
        AppToast.show(
          context,
          severity: ToastSeverity.success,
          message: translations.common.notConnected,
        );
      case ToastDialogGalleryKind.toastInfo:
        AppToast.show(
          context,
          severity: ToastSeverity.info,
          title: translations.devGallery.caseToastInfo,
          message: translations.common.notConnected,
        );
      case ToastDialogGalleryKind.toastWarning:
        AppToast.show(
          context,
          severity: ToastSeverity.warning,
          title: translations.devGallery.caseToastWarning,
          message: translations.common.notConnected,
        );
      case ToastDialogGalleryKind.toastError:
        AppToast.show(
          context,
          severity: ToastSeverity.error,
          message: translations.common.notConnected,
          duration: null,
        );
      case ToastDialogGalleryKind.dialogConfirm:
        unawaited(
          AppConfirmationDialog.show(
            context,
            intent: ConfirmationIntent.confirm,
            title: translations.devGallery.caseDialogConfirm,
            body: translations.common.notConnected,
          ),
        );
      case ToastDialogGalleryKind.dialogDestroy:
        unawaited(
          AppConfirmationDialog.show(
            context,
            intent: ConfirmationIntent.destroy,
            title: translations.devGallery.caseDialogDestroy,
            body: translations.common.notConnected,
          ),
        );
    }
  }
}

String _caseLabel(Translations translations, ToastDialogGalleryKind kind) {
  return switch (kind) {
    ToastDialogGalleryKind.toastSuccess => translations.devGallery.caseToastSuccess,
    ToastDialogGalleryKind.toastInfo => translations.devGallery.caseToastInfo,
    ToastDialogGalleryKind.toastWarning => translations.devGallery.caseToastWarning,
    ToastDialogGalleryKind.toastError => translations.devGallery.caseToastError,
    ToastDialogGalleryKind.dialogConfirm => translations.devGallery.caseDialogConfirm,
    ToastDialogGalleryKind.dialogDestroy => translations.devGallery.caseDialogDestroy,
  };
}
