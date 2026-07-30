import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/profile/widgets/permission_rationale_assets.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/permissions/permission_service.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/escape_dismissible_overlay.dart';

/// The user's selection on the permission rationale sheet. [openSettings] is
/// the one-way-door recovery path for permanently-denied; [continueRequest]
/// proceeds to the OS prompt. [dismiss] is the default when the sheet
/// returns no value.
enum PermissionRationaleResult { continueRequest, openSettings, dismiss }

/// Shows the permission rationale sheet. Call this *before*
/// `PermissionService.requestStatus` — always rationale before prompt. Pass
/// [permanentlyDenied] so a one-way-door permission offers "Open settings"
/// rather than a re-prompt.
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
    builder: (sheetContext) => ColoredBox(
      // FSheet paints no surface of its own; give it an opaque background.
      color: sheetContext.theme.colors.background,
      child: EscapeDismissibleOverlay(
        child: PermissionRationaleBody(
          permission: permission,
          permanentlyDenied: permanentlyDenied,
          onContinue: () =>
              Navigator.of(sheetContext).pop(PermissionRationaleResult.continueRequest),
          onOpenSettings: () =>
              Navigator.of(sheetContext).pop(PermissionRationaleResult.openSettings),
          onDismiss: () => Navigator.of(sheetContext).pop(PermissionRationaleResult.dismiss),
        ),
      ),
    ),
  );
  return result ?? PermissionRationaleResult.dismiss;
}

/// Reusable body of the permission rationale sheet; extracted so the
/// dev-gallery can render it deterministically outside a real modal sheet.
class PermissionRationaleBody extends StatelessWidget {
  const PermissionRationaleBody({
    required this.permission,
    required this.onContinue,
    required this.onOpenSettings,
    required this.onDismiss,
    this.permanentlyDenied = false,
    super.key,
  });

  final AppPermission permission;

  /// Switches the primary action from "Continue" to "Open settings"; never
  /// offers a re-prompt (the one-way-door rule).
  final bool permanentlyDenied;

  /// Only offered when [permanentlyDenied] is false.
  final VoidCallback onContinue;

  final VoidCallback onOpenSettings;

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
            // Row respects ambient Directionality, so the icon mirrors under RTL.
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
            _actions(translations),
          ],
        ),
      ),
    );
  }

  Widget _actions(Translations translations) {
    final primary = permanentlyDenied
        ? (
            key: 'permission-rationale-open-settings',
            label: translations.permission.openSettings,
            onPress: onOpenSettings,
          )
        : (
            key: 'permission-rationale-continue',
            label: translations.permission.continueRequest,
            onPress: onContinue,
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FButton(
          key: ValueKey(primary.key),
          onPress: primary.onPress,
          child: Text(primary.label),
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
