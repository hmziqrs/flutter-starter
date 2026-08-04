import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/features/profile/widgets/permission_rationale_sheet.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/permissions/permission_service.dart';
import 'package:starter/shared/theme/app_sizes.dart';
import 'package:starter/shared/theme/app_spacing.dart';

part 'permissions_gallery_cases.freezed.dart';

@freezed
abstract class PermissionGalleryState with _$PermissionGalleryState {
  const factory PermissionGalleryState({
    required AppPermission permission,
    required bool permanentlyDenied,
    required bool showDeniedAlert,
  }) = _PermissionGalleryState;
}

List<GalleryCase> buildPermissionsGalleryCases() {
  return buildTypedGalleryCases<PermissionGalleryState>(
    idPrefix: 'permissions',
    screenId: 'permissions',
    screenLabelBuilder: (t) => t.devGallery.screenPermissions,
    definitions: [
      galleryCaseOf(
        'rationale',
        (t) => t.devGallery.casePermissionRationale,
        const PermissionGalleryState(
          permission: AppPermission.photos,
          permanentlyDenied: false,
          showDeniedAlert: false,
        ),
      ),
      galleryCaseOf(
        'denied',
        (t) => t.devGallery.casePermissionDenied,
        const PermissionGalleryState(
          permission: AppPermission.photos,
          permanentlyDenied: false,
          showDeniedAlert: true,
        ),
      ),
      galleryCaseOf(
        'permanentlyDenied',
        (t) => t.devGallery.casePermissionPermanentlyDenied,
        const PermissionGalleryState(
          permission: AppPermission.photos,
          permanentlyDenied: true,
          showDeniedAlert: false,
        ),
      ),
    ],
    pageFactory: (context, state) => _PermissionPreview(state: state),
  );
}

class _PermissionPreview extends StatelessWidget {
  const _PermissionPreview({required this.state});

  final PermissionGalleryState state;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.formContentMaxWidth),
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
