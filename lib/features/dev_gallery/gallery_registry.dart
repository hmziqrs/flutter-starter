import 'package:starter/app/config/app_config.dart';
import 'package:starter/features/dev_gallery/cases/production_gallery_cases.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/features/dev_gallery/system/system_gallery_cases.dart';

/// Builds the complete development-only registry and rejects ambiguous IDs.
List<GalleryCase> buildGalleryRegistry({required AppConfig config}) {
  final cases = <GalleryCase>[
    ...buildProductionGalleryCases(),
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
