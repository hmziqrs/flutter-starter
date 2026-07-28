import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/features/profile/widgets/permission_rationale_sheet.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/permissions/permission_service.dart';
import 'package:starter/shared/theme/app_spacing.dart';

/// Immutable, deterministic preview state for the permission rationale gallery
/// cases. One per (permission, denied-state); no timers, no plugin, no
/// persistence — the gallery renders [PermissionRationaleBody] directly in a
/// card (sheets are modal, so the gallery embeds the same body rather than
/// triggering a real sheet, keeping the preview hermetic).
final class PermissionGalleryState {
  const PermissionGalleryState({
    required this.permission,
    required this.permanentlyDenied,
    required this.showDeniedAlert,
  });

  final AppPermission permission;
  final bool permanentlyDenied;

  /// Prepends a "denied" alert so the denied case is visually distinct from the
  /// promptable rationale case (both are otherwise the same body).
  final bool showDeniedAlert;
}

/// Builds the permission rationale gallery cases: the promptable rationale, the
/// denied state, and the permanently-denied (one-way-door) state — all for the
/// avatar flow's `photos` permission so the three states are directly
/// comparable. Gated by `developmentToolsEnabled` via the registry caller.
List<GalleryCase> buildPermissionsGalleryCases() {
  return [
    TypedGalleryCase<PermissionGalleryState>(
      id: 'permissions.rationale',
      screenId: 'permissions',
      screenLabelBuilder: (translations) => translations.devGallery.screenPermissions,
      caseLabelBuilder: (translations) => translations.devGallery.casePermissionRationale,
      stateFactory: (_) => const PermissionGalleryState(
        permission: AppPermission.photos,
        permanentlyDenied: false,
        showDeniedAlert: false,
      ),
      pageFactory: (context, state) => _PermissionPreview(state: state),
    ),
    TypedGalleryCase<PermissionGalleryState>(
      id: 'permissions.denied',
      screenId: 'permissions',
      screenLabelBuilder: (translations) => translations.devGallery.screenPermissions,
      caseLabelBuilder: (translations) => translations.devGallery.casePermissionDenied,
      stateFactory: (_) => const PermissionGalleryState(
        permission: AppPermission.photos,
        permanentlyDenied: false,
        showDeniedAlert: true,
      ),
      pageFactory: (context, state) => _PermissionPreview(state: state),
    ),
    TypedGalleryCase<PermissionGalleryState>(
      id: 'permissions.permanentlyDenied',
      screenId: 'permissions',
      screenLabelBuilder: (translations) => translations.devGallery.screenPermissions,
      caseLabelBuilder: (translations) => translations.devGallery.casePermissionPermanentlyDenied,
      stateFactory: (_) => const PermissionGalleryState(
        permission: AppPermission.photos,
        permanentlyDenied: true,
        showDeniedAlert: false,
      ),
      pageFactory: (context, state) => _PermissionPreview(state: state),
    ),
  ];
}

class _PermissionPreview extends StatelessWidget {
  const _PermissionPreview({required this.state});

  final PermissionGalleryState state;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: FCard(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (state.showDeniedAlert) ...[
                    FAlert(
                      icon: const Icon(FLucideIcons.circleAlert),
                      title: Text(context.t.permission.denied),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  // The same body the modal sheet renders — buttons are wired to
                  // no-ops so the preview stays deterministic (no real prompt,
                  // no navigation). The permanently-denied case renders the
                  // blocked-state alert + "Open settings" action in place of a
                  // re-prompt (the one-way-door rule).
                  PermissionRationaleBody(
                    permission: state.permission,
                    permanentlyDenied: state.permanentlyDenied,
                    onContinue: () {},
                    onOpenSettings: () {},
                    onDismiss: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
