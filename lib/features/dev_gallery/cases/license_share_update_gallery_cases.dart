import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/features/settings/license_page.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/sharing/share_service.dart';
import 'package:starter/infrastructure/updates/app_update_service.dart';
import 'package:starter/shared/theme/app_sizes.dart';
import 'package:starter/shared/theme/app_spacing.dart';

/// Builds the license / share / in-app-update gallery cases.
///
/// Three concerns, one bundle (the feature doc sequences them together because
/// they share the diagnostics dev triggers and the `AppBuildInfo` / settings
/// seams):
///
/// * **License** — the [AboutLicensePage] wrapper over Flutter's local license
///   registry (backend-free).
/// * **Share** — one deterministic preview per [ShareResult] variant. The
///   preview never pops a real OS sheet (C2: the gallery never fakes a backend
///   action); it renders the typed result state the production adapter would
///   surface.
/// * **Update** — one deterministic preview per [UpdateAvailability] variant.
///   The preview never calls the Play / App Store plugin; it renders the typed
///   availability state, including the server-only [UpdateAvailability.required]
///   so the gallery documents that variant even though the OS-store adapters
///   never produce it.
///
/// All fixtures are deterministic — no plugins, no timers, no persistence.
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
        pageFactory: (context, state) => _ShareResultPreview(result: state),
      ),
    for (final availability in UpdateAvailability.values)
      TypedGalleryCase<UpdateAvailability>(
        id: 'appUpdate.${availability.name}',
        screenId: 'appUpdate',
        screenLabelBuilder: (translations) => translations.devGallery.screenAppUpdate,
        caseLabelBuilder: (translations) => _updateAvailabilityLabel(translations, availability),
        stateFactory: (_) => availability,
        pageFactory: (context, state) => _UpdateAvailabilityPreview(availability: state),
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

/// Centers a typed [ShareResult] preview so the state the production adapter
/// would surface is visible without triggering the OS share sheet.
class _ShareResultPreview extends StatelessWidget {
  const _ShareResultPreview({required this.result});

  final ShareResult result;

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
                  Icon(_shareIcon(result), color: context.theme.colors.primary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          translations.devGallery.screenShare,
                          style: context.theme.typography.body.lg,
                        ),
                        Text(_shareResultLabel(translations, result)),
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

IconData _shareIcon(ShareResult result) {
  return switch (result) {
    ShareResult.success => FLucideIcons.check,
    ShareResult.unavailable => FLucideIcons.ban,
    ShareResult.cancelled => FLucideIcons.x,
  };
}

/// Centers a typed [UpdateAvailability] preview so the state the production
/// adapter would surface is visible without calling the Play / App Store plugin.
class _UpdateAvailabilityPreview extends StatelessWidget {
  const _UpdateAvailabilityPreview({required this.availability});

  final UpdateAvailability availability;

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
                    _updateIcon(availability),
                    color: availability == UpdateAvailability.required
                        ? context.theme.colors.error
                        : context.theme.colors.primary,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          translations.devGallery.screenAppUpdate,
                          style: context.theme.typography.body.lg,
                        ),
                        Text(_updateAvailabilityLabel(translations, availability)),
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

IconData _updateIcon(UpdateAvailability availability) {
  return switch (availability) {
    UpdateAvailability.noUpdate => FLucideIcons.check,
    UpdateAvailability.available => FLucideIcons.download,
    UpdateAvailability.required => FLucideIcons.alertTriangle,
  };
}
