import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/profile/widgets/permission_rationale_assets.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/permissions/permission_service.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/escape_dismissible_overlay.dart';

/// The user's selection on the permission rationale sheet.
///
/// The permanently-denied state offers [openSettings] (the one-way-door recovery
/// path) where the promptable state offers [continueRequest] (proceed to the OS
/// prompt). [dismiss] covers Escape / barrier dismissal and is the default when
/// the sheet returns no value.
enum PermissionRationaleResult {
  /// Proceed to the OS permission prompt (only offered when the permission is
  /// still promptable — NOT when permanently denied).
  continueRequest,

  /// Open the system settings page (the recovery path for permanently denied).
  openSettings,

  /// Dismissed via Escape, barrier tap, or "Not now".
  dismiss,
}

/// Shows the permission rationale sheet (ForUI `FSheet` wrapped in
/// [EscapeDismissibleOverlay]) and resolves to the user's selection.
///
/// **Rationale before prompt, always.** Call this *before* invoking
/// `PermissionService.requestStatus`: stores reject apps that request without
/// context, and a rationale step prevents silent permanent denials. The
/// permanently-denied state is a one-way door — pass [permanentlyDenied] so the
/// sheet offers "Open settings" (the only recovery path) and NOT a re-prompt,
/// which is the single most common implementation bug.
///
/// Returns [PermissionRationaleResult.dismiss] when the user dismisses via
/// Escape / barrier tap. The sheet's slide animation is ForUI-built-in (the
/// feature spec motion audit notes no custom entrance is added); navigation
/// never gates on its completion.
Future<PermissionRationaleResult> showPermissionRationaleSheet({
  required BuildContext context,
  required AppPermission permission,
  bool permanentlyDenied = false,
}) async {
  final result = await showFSheet<PermissionRationaleResult>(
    context: context,
    side: FLayout.btt,
    draggable: false,
    useSafeArea: true,
    builder: (sheetContext) => EscapeDismissibleOverlay(
      child: PermissionRationaleBody(
        permission: permission,
        permanentlyDenied: permanentlyDenied,
        onContinue: () => Navigator.of(sheetContext).pop(PermissionRationaleResult.continueRequest),
        onOpenSettings: () =>
            Navigator.of(sheetContext).pop(PermissionRationaleResult.openSettings),
        onDismiss: () => Navigator.of(sheetContext).pop(PermissionRationaleResult.dismiss),
      ),
    ),
  );
  return result ?? PermissionRationaleResult.dismiss;
}

/// Reusable body of the permission rationale sheet.
///
/// Extracted from the modal so the dev-gallery `PreviewFrame` fixture can render
/// the same content deterministically (sheets are modal, so the gallery embeds
/// this body directly in a card rather than triggering a real sheet). The avatar
/// flow and future permission consumers reuse it. Feature-local under
/// `lib/features/profile/widgets/` until a third consumer arrives, then promote
/// to `lib/shared/widgets/` (feature spec audit: shared-extraction threshold).
class PermissionRationaleBody extends StatelessWidget {
  const PermissionRationaleBody({
    required this.permission,
    required this.onContinue,
    required this.onOpenSettings,
    required this.onDismiss,
    this.permanentlyDenied = false,
    super.key,
  });

  /// The permission this rationale explains. Drives the title, rationale copy,
  /// and the leading icon (exhaustive switch).
  final AppPermission permission;

  /// `true` when the OS reports the permission permanently denied. Switches the
  /// primary action from "Continue" (request) to "Open settings" and never
  /// offers a re-prompt — the one-way-door rule.
  final bool permanentlyDenied;

  /// Invoked when the user chooses to proceed to the OS prompt. Only offered
  /// when [permanentlyDenied] is false.
  final VoidCallback onContinue;

  /// Invoked when the user chooses to open system settings (the recovery path).
  final VoidCallback onOpenSettings;

  /// Invoked when the user dismisses the rationale ("Not now" / Escape).
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final copy = PermissionRationaleCopy.forPermission(translations, permission);
    return Semantics(
      label: copy.title,
      container: true,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The leading icon + title sit in a Row so the icon mirrors under
            // RTL (Row respects the ambient Directionality): leading in LTR,
            // trailing in ar. This is the direction-sensitive surface called out
            // by the feature spec's RTL note.
            Row(
              children: [
                Icon(copy.icon, size: 28),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(copy.title, style: context.theme.typography.display.lg),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(copy.rationale, style: context.theme.typography.body.md),
            if (permanentlyDenied) ...[
              const SizedBox(height: AppSpacing.md),
              FAlert(
                icon: const Icon(FLucideIcons.octagonAlert),
                title: Text(translations.permission.permanentlyDenied),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            if (permanentlyDenied)
              _permanentlyDeniedActions(translations)
            else
              _promptableActions(translations),
          ],
        ),
      ),
    );
  }

  Widget _promptableActions(Translations translations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FButton(
          key: const ValueKey('permission-rationale-continue'),
          onPress: onContinue,
          child: Text(translations.permission.continueRequest),
        ),
        const SizedBox(height: AppSpacing.sm),
        FButton(
          key: const ValueKey('permission-rationale-dismiss'),
          variant: .outline,
          onPress: onDismiss,
          child: Text(translations.permission.notNow),
        ),
      ],
    );
  }

  Widget _permanentlyDeniedActions(Translations translations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FButton(
          key: const ValueKey('permission-rationale-open-settings'),
          onPress: onOpenSettings,
          child: Text(translations.permission.openSettings),
        ),
        const SizedBox(height: AppSpacing.sm),
        FButton(
          key: const ValueKey('permission-rationale-dismiss'),
          variant: .outline,
          onPress: onDismiss,
          child: Text(translations.permission.notNow),
        ),
      ],
    );
  }
}
