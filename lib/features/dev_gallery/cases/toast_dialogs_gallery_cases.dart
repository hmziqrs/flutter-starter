import 'dart:async';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/feedback/app_confirmation_dialog.dart';
import 'package:starter/shared/widgets/feedback/app_toast.dart';

/// The deterministic kind of toast / dialog rendered by the gallery fixture.
///
/// One variant per `ToastSeverity` plus one per `ConfirmationIntent`. The
/// fixture never fakes a backend action (audit #13): every case surfaces
/// `common.notConnected` (or the cancel side of a confirm) and never claims
/// success for an operation that did not run.
enum ToastDialogGalleryKind {
  toastSuccess,
  toastInfo,
  toastWarning,
  toastError,
  dialogConfirm,
  dialogDestroy,
}

/// Builds the toast + confirmation-dialog gallery cases.
///
/// Each case mounts a single trigger button; pressing it routes through the
/// production [AppToast] / [AppConfirmationDialog] wrappers, which find the
/// `FToaster` ancestor provided by `PreviewFrame` (and the `Navigator` likewise
/// mounted in `PreviewFrame`). The triggers carry stable keys so golden
/// capture + widget tests can drive them deterministically.
///
/// The gallery is wired in `gallery_registry.dart` by the integrator — the case
/// builder is feature-owned and registered alongside the other Wave-6 surfaces.
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
        padding: const EdgeInsets.all(AppSpacing.xl),
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
        // Persistent (`duration: null`) — the no-backend error surface must not
        // be hidden by a transient timeout in the deterministic preview.
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
