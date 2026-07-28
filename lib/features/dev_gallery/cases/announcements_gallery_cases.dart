import 'package:flutter/widgets.dart';
import 'package:starter/features/announcements/announcement_banner.dart';
import 'package:starter/features/announcements/announcement_fixtures.dart';
import 'package:starter/features/announcements/announcement_view_data.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/app_spacing.dart';

/// Immutable, deterministic preview state for the announcements banner gallery
/// cases. One per [AnnouncementSeverity]; no timers, no controller, no
/// persistence (C2: the gallery never fakes a backend action — the dismiss /
/// action callbacks are no-ops so the preview stays stable).
final class AnnouncementsGalleryState {
  const AnnouncementsGalleryState._(this.severity, this.labelBuilder);

  final AnnouncementSeverity severity;
  final String Function(Translations translations) labelBuilder;

  static final info = AnnouncementsGalleryState._(
    AnnouncementSeverity.info,
    (t) => t.devGallery.caseAnnouncementsInfo,
  );
  static final success = AnnouncementsGalleryState._(
    AnnouncementSeverity.success,
    (t) => t.devGallery.caseAnnouncementsSuccess,
  );
  static final warning = AnnouncementsGalleryState._(
    AnnouncementSeverity.warning,
    (t) => t.devGallery.caseAnnouncementsWarning,
  );
  static final critical = AnnouncementsGalleryState._(
    AnnouncementSeverity.critical,
    (t) => t.devGallery.caseAnnouncementsCritical,
  );

  static final values = <AnnouncementsGalleryState>[info, success, warning, critical];
}

/// Builds the announcements banner gallery cases: one per severity
/// (info / success / warning / critical). Each case mounts the production
/// [AnnouncementBannerView] directly with the named fixture for that severity
/// and no-op callbacks, so the preview is fully deterministic and exercises the
/// real visual (the controller path is covered by unit tests).
List<GalleryCase> buildAnnouncementsGalleryCases() {
  return [
    for (final entry in AnnouncementsGalleryState.values)
      TypedGalleryCase<AnnouncementsGalleryState>(
        id: 'announcements.${entry.severity.name}',
        screenId: 'announcements',
        screenLabelBuilder: (translations) => translations.devGallery.screenAnnouncements,
        caseLabelBuilder: entry.labelBuilder,
        stateFactory: (_) => entry,
        pageFactory: (context, state) => _AnnouncementsPreview(state: state),
      ),
  ];
}

/// Frames [AnnouncementBannerView] above a placeholder body so the preview
/// mirrors the production mount (banner slot above content). The fixture is
/// resolved by severity; dismiss / action callbacks are no-ops so the preview
/// stays stable across frames.
class _AnnouncementsPreview extends StatelessWidget {
  const _AnnouncementsPreview({required this.state});

  final AnnouncementsGalleryState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnnouncementBannerView(
          announcement: AnnouncementFixtures.forSeverity(state.severity),
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
