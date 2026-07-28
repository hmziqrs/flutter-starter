import 'package:starter/app/config/app_config.dart';
import 'package:starter/features/dev_gallery/cases/a11y_presets_gallery_cases.dart';
import 'package:starter/features/dev_gallery/cases/analytics_gallery_cases.dart';
import 'package:starter/features/dev_gallery/cases/announcements_gallery_cases.dart';
import 'package:starter/features/dev_gallery/cases/biometric_gallery_cases.dart';
import 'package:starter/features/dev_gallery/cases/busy_indicator_gallery_cases.dart';
import 'package:starter/features/dev_gallery/cases/connectivity_gallery_cases.dart';
import 'package:starter/features/dev_gallery/cases/force_update_gallery_cases.dart';
import 'package:starter/features/dev_gallery/cases/form_scaffolding_gallery_cases.dart';
import 'package:starter/features/dev_gallery/cases/haptics_gallery_cases.dart';
import 'package:starter/features/dev_gallery/cases/license_share_update_gallery_cases.dart';
import 'package:starter/features/dev_gallery/cases/mfa_otp_gallery_cases.dart';
import 'package:starter/features/dev_gallery/cases/notifications_gallery_cases.dart';
import 'package:starter/features/dev_gallery/cases/permissions_gallery_cases.dart';
import 'package:starter/features/dev_gallery/cases/production_gallery_cases.dart';
import 'package:starter/features/dev_gallery/cases/pull_refresh_gallery_cases.dart';
import 'package:starter/features/dev_gallery/cases/session_gallery_cases.dart';
import 'package:starter/features/dev_gallery/cases/skeleton_gallery_cases.dart';
import 'package:starter/features/dev_gallery/cases/splash_gallery_cases.dart';
import 'package:starter/features/dev_gallery/cases/state_views_gallery_cases.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/features/dev_gallery/system/system_gallery_cases.dart';

/// Builds the complete development-only registry and rejects ambiguous IDs.
List<GalleryCase> buildGalleryRegistry({required AppConfig config}) {
  final cases = <GalleryCase>[
    ...buildProductionGalleryCases(),
    ...buildConnectivityGalleryCases(),
    ...buildForceUpdateGalleryCases(),
    ...buildBusyIndicatorGalleryCases(),
    ...buildPullRefreshGalleryCases(),
    // Wave-3 shared widgets + screens.
    ...buildStateViewsGalleryCases(),
    ...buildSkeletonGalleryCases(),
    ...buildFormScaffoldingGalleryCases(),
    ...buildSplashGalleryCases(),
    ...buildAnnouncementsGalleryCases(),
    // Wave-4 feature surfaces registered by their gallery contributors.
    ...buildSessionGalleryCases(),
    ...buildAnalyticsGalleryCases(),
    ...buildBiometricGalleryCases(),
    // Wave-5a feature surfaces.
    ...buildHapticsGalleryCases(),
    ...buildA11yPresetsGalleryCases(),
    ...buildSystemGalleryCases(config: config),
    // Wave-5b feature surfaces (mfa-otp, push, permissions-media,
    // license-share-update). Gated by developmentToolsEnabled via the
    // registry caller (the dev gallery route is only mounted in development).
    ...buildMfaOtpGalleryCases(),
    ...buildNotificationsGalleryCases(),
    ...buildPermissionsGalleryCases(),
    ...buildLicenseShareUpdateGalleryCases(),
  ];
  final ids = <String>{};
  for (final galleryCase in cases) {
    if (galleryCase.id.trim().isEmpty || galleryCase.screenId.trim().isEmpty) {
      throw StateError('Gallery case and screen IDs must not be empty.');
    }
    if (!ids.add(galleryCase.id)) {
      throw StateError('Duplicate gallery case ID: ${galleryCase.id}');
    }
  }
  return List.unmodifiable(cases);
}
