import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/features/dev_gallery/widgets/gallery_preview_body.dart';
import 'package:starter/features/settings/license_page.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/sharing/share_service.dart';
import 'package:starter/infrastructure/updates/app_update_service.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/containers/app_card.dart';

List<GalleryCase> buildLicenseShareUpdateGalleryCases() {
  return <GalleryCase>[
    TypedGalleryCase<void>(
      id: 'license.about',
      screenId: 'license',
      screenLabelBuilder: (translations) => translations.devGallery.screenLicense,
      caseLabelBuilder: (translations) => translations.settings.about.license,
      stateFactory: (_) {},
      pageFactory: (context, state) => const AboutLicensePage(),
    ),
    ...buildEnumGalleryCases<ShareResult>(
      values: ShareResult.values,
      idPrefix: 'share',
      screenId: 'share',
      screenLabelBuilder: (translations) => translations.devGallery.screenShare,
      caseLabelBuilder: (result) =>
          (translations) => _shareResultLabel(translations, result),
      pageFactory: (context, state) => _IconLabelCard(
        screenLabel: (t) => t.devGallery.screenShare,
        caseLabel: (t) => _shareResultLabel(t, state),
        icon: _shareIcon(state),
      ),
    ),
    ...buildEnumGalleryCases<UpdateAvailability>(
      values: UpdateAvailability.values,
      idPrefix: 'appUpdate',
      screenId: 'appUpdate',
      screenLabelBuilder: (translations) => translations.devGallery.screenAppUpdate,
      caseLabelBuilder: (availability) =>
          (translations) => _updateAvailabilityLabel(translations, availability),
      pageFactory: (context, state) => _IconLabelCard(
        screenLabel: (t) => t.devGallery.screenAppUpdate,
        caseLabel: (t) => _updateAvailabilityLabel(t, state),
        icon: _updateIcon(state),
        iconColorError: state == UpdateAvailability.required,
      ),
    ),
  ];
}

String _shareResultLabel(Translations translations, ShareResult result) {
  return switch (result) {
    ShareResult.success => translations.share.success,
    ShareResult.unavailable => translations.share.unavailable,
    ShareResult.cancelled => translations.share.cancelled,
  };
}

String _updateAvailabilityLabel(
  Translations translations,
  UpdateAvailability availability,
) {
  return switch (availability) {
    UpdateAvailability.noUpdate => translations.update.notAvailable,
    UpdateAvailability.available => translations.update.available,
    UpdateAvailability.required => translations.update.required,
  };
}

IconData _shareIcon(ShareResult result) {
  return switch (result) {
    ShareResult.success => FLucideIcons.check,
    ShareResult.unavailable => FLucideIcons.ban,
    ShareResult.cancelled => FLucideIcons.x,
  };
}

IconData _updateIcon(UpdateAvailability availability) {
  return switch (availability) {
    UpdateAvailability.noUpdate => FLucideIcons.check,
    UpdateAvailability.available => FLucideIcons.download,
    UpdateAvailability.required => FLucideIcons.alertTriangle,
  };
}

class _IconLabelCard extends StatelessWidget {
  const _IconLabelCard({
    required this.screenLabel,
    required this.caseLabel,
    required this.icon,
    this.iconColorError = false,
  });

  final GalleryLabelBuilder screenLabel;
  final GalleryLabelBuilder caseLabel;
  final IconData icon;
  final bool iconColorError;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    return GalleryPreviewBody(
      child: AppCard(
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColorError ? context.theme.colors.error : context.theme.colors.primary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(screenLabel(translations), style: context.theme.typography.body.lg),
                  Text(caseLabel(translations)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
