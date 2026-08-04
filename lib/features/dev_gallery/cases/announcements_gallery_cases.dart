import 'package:flutter/widgets.dart';
import 'package:starter/features/announcements/announcement_banner.dart';
import 'package:starter/features/announcements/announcement_fixtures.dart';
import 'package:starter/features/announcements/announcement_view_data.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/app_spacing.dart';

List<GalleryCase> buildAnnouncementsGalleryCases() {
  return buildEnumGalleryCases<AnnouncementSeverity>(
    values: AnnouncementSeverity.values,
    idPrefix: 'announcements',
    screenId: 'announcements',
    screenLabelBuilder: (translations) => translations.devGallery.screenAnnouncements,
    caseLabelBuilder: (severity) =>
        (translations) => _caseLabel(translations, severity),
    pageFactory: (context, state) => _AnnouncementsPreview(severity: state),
  );
}

String _caseLabel(Translations t, AnnouncementSeverity severity) => switch (severity) {
  AnnouncementSeverity.info => t.devGallery.caseAnnouncementsInfo,
  AnnouncementSeverity.success => t.devGallery.caseAnnouncementsSuccess,
  AnnouncementSeverity.warning => t.devGallery.caseAnnouncementsWarning,
  AnnouncementSeverity.critical => t.devGallery.caseAnnouncementsCritical,
};

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
