import 'package:starter/app/config/app_config.dart';
import 'package:starter/features/dev_gallery/cases/analytics_gallery_cases.dart';
import 'package:starter/features/dev_gallery/cases/announcements_gallery_cases.dart';
import 'package:starter/features/dev_gallery/cases/biometric_gallery_cases.dart';
import 'package:starter/features/dev_gallery/cases/busy_indicator_gallery_cases.dart';
import 'package:starter/features/dev_gallery/cases/connectivity_gallery_cases.dart';
import 'package:starter/features/dev_gallery/cases/force_update_gallery_cases.dart';
import 'package:starter/features/dev_gallery/cases/form_scaffolding_gallery_cases.dart';
import 'package:starter/features/dev_gallery/cases/production_gallery_cases.dart';
import 'package:starter/features/dev_gallery/cases/session_gallery_cases.dart';
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
    // Wave-3 shared widgets + screens.
    ...buildStateViewsGalleryCases(),
    ...buildFormScaffoldingGalleryCases(),
    ...buildSplashGalleryCases(),
    ...buildAnnouncementsGalleryCases(),
    // Wave-4 feature surfaces registered by their gallery contributors.
    ...buildSessionGalleryCases(),
    ...buildAnalyticsGalleryCases(),
    ...buildBiometricGalleryCases(),
    ...buildSystemGalleryCases(config: config),
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
