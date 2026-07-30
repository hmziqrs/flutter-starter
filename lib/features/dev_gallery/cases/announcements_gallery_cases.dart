import 'package:flutter/widgets.dart';
import 'package:starter/features/announcements/announcement_banner.dart';
import 'package:starter/features/announcements/announcement_fixtures.dart';
import 'package:starter/features/announcements/announcement_view_data.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/app_spacing.dart';

/// Builds the announcements banner gallery cases: one per severity. Each case
/// mounts the production [AnnouncementBannerView] with no-op callbacks.
List<GalleryCase> buildAnnouncementsGalleryCases() {
  return [
    for (final severity in AnnouncementSeverity.values)
      TypedGalleryCase<AnnouncementSeverity>(
        id: 'announcements.${severity.name}',
        screenId: 'announcements',
        screenLabelBuilder: (translations) => translations.devGallery.screenAnnouncements,
        caseLabelBuilder: (translations) => _caseLabel(translations, severity),
        stateFactory: (_) => severity,
        pageFactory: (context, state) => _AnnouncementsPreview(severity: state),
      ),
  ];
}

String _caseLabel(Translations t, AnnouncementSeverity severity) => switch (severity) {
  AnnouncementSeverity.info => t.devGallery.caseAnnouncementsInfo,
  AnnouncementSeverity.success => t.devGallery.caseAnnouncementsSuccess,
  AnnouncementSeverity.warning => t.devGallery.caseAnnouncementsWarning,
  AnnouncementSeverity.critical => t.devGallery.caseAnnouncementsCritical,
};

/// Frames [AnnouncementBannerView] above a placeholder body, mirroring the
/// production mount (banner slot above content).
class _AnnouncementsPreview extends StatelessWidget {
  const _AnnouncementsPreview({required this.severity});

  final AnnouncementSeverity severity;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnnouncementBannerView(
          announcement: AnnouncementFixtures.forSeverity(severity),
          onDismiss: () {},
          onAction: () {},
        ),
        Expanded(
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(context.t.devGallery.preview),
          ),
        ),
      ],
    );
  }
}
