import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/profile/widgets/permission_rationale_assets.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/permissions/permission_service.dart';
import 'package:starter/shared/theme/app_presentation_tokens.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/app_bottom_sheet.dart';

enum PermissionRationaleResult { continueRequest, openSettings, dismiss }

Future<PermissionRationaleResult> showPermissionRationaleSheet({
  required BuildContext context,
  required AppPermission permission,
  bool permanentlyDenied = false,
}) async {
  final result = await showAppBottomSheet<PermissionRationaleResult>(
    context: context,
    draggable: false,
    builder: (sheetContext) => PermissionRationaleBody(
      permission: permission,
      permanentlyDenied: permanentlyDenied,
      onContinue: () => Navigator.of(sheetContext).pop(PermissionRationaleResult.continueRequest),
      onOpenSettings: () => Navigator.of(sheetContext).pop(PermissionRationaleResult.openSettings),
      onDismiss: () => Navigator.of(sheetContext).pop(PermissionRationaleResult.dismiss),
    ),
  );
  return result ?? PermissionRationaleResult.dismiss;
}

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

  final bool permanentlyDenied;

  final VoidCallback onContinue;

  final VoidCallback onOpenSettings;

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final spacing = context.spacing;
    final copy = PermissionRationaleCopy.forPermission(translations, permission);
    return Semantics(
      label: copy.title,
      container: true,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: context.presentationTokens.formContentMaxWidth,
          ),
          child: Padding(
            padding: EdgeInsets.all(spacing.xl),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(copy.icon, size: 28),
                      SizedBox(width: spacing.md),
                      Expanded(
                        child: Text(copy.title, style: context.theme.typography.display.lg),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.md),
                  Text(copy.rationale, style: context.theme.typography.body.md),
                  if (permanentlyDenied) ...[
                    SizedBox(height: spacing.md),
                    FAlert(
                      icon: const Icon(FLucideIcons.octagonAlert),
                      title: Text(translations.permission.permanentlyDenied),
                    ),
                  ],
                  SizedBox(height: spacing.xl),
                  _actions(translations),
                ],
              ),
            ),
          ),
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
