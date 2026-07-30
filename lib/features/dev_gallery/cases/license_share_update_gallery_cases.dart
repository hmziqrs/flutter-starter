import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/features/settings/license_page.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/sharing/share_service.dart';
import 'package:starter/infrastructure/updates/app_update_service.dart';
import 'package:starter/shared/theme/app_sizes.dart';
import 'package:starter/shared/theme/app_spacing.dart';

/// Builds the license, share-result, and app-update-availability gallery
/// cases. Share and update previews render the typed result/availability
/// state directly, without popping a real OS share sheet or store plugin.
List<GalleryCase> buildLicenseShareUpdateGalleryCases() {
  return [
    TypedGalleryCase<void>(
      id: 'license.about',
      screenId: 'license',
      screenLabelBuilder: (translations) => translations.devGallery.screenLicense,
      caseLabelBuilder: (translations) => translations.settings.about.license,
      stateFactory: (_) {},
      pageFactory: (context, state) => const AboutLicensePage(),
    ),
    for (final result in ShareResult.values)
      TypedGalleryCase<ShareResult>(
        id: 'share.${result.name}',
        screenId: 'share',
        screenLabelBuilder: (translations) => translations.devGallery.screenShare,
        caseLabelBuilder: (translations) => _shareResultLabel(translations, result),
        stateFactory: (_) => result,
        pageFactory: (context, state) => _IconLabelCard(
          screenLabel: (t) => t.devGallery.screenShare,
          caseLabel: (t) => _shareResultLabel(t, state),
          icon: _shareIcon(state),
        ),
      ),
    for (final availability in UpdateAvailability.values)
      TypedGalleryCase<UpdateAvailability>(
        id: 'appUpdate.${availability.name}',
        screenId: 'appUpdate',
        screenLabelBuilder: (translations) => translations.devGallery.screenAppUpdate,
        caseLabelBuilder: (translations) => _updateAvailabilityLabel(translations, availability),
        stateFactory: (_) => availability,
        pageFactory: (context, state) => _IconLabelCard(
          screenLabel: (t) => t.devGallery.screenAppUpdate,
          caseLabel: (t) => _updateAvailabilityLabel(t, availability),
          icon: _updateIcon(availability),
          iconColorError: availability == UpdateAvailability.required,
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

/// Shared card layout for the share/update-availability previews: an icon
/// beside a screen label and case label.
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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.formContentMaxWidth),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: FCard(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: iconColorError
                        ? context.theme.colors.error
                        : context.theme.colors.primary,
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
          ),
        ),
      ),
    );
  }
}
