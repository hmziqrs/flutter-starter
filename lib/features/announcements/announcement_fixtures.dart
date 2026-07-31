import 'package:starter/features/announcements/announcement_view_data.dart';

abstract final class AnnouncementFixtures {
  static final Announcement welcome = Announcement(
    id: 'welcome',
    severity: AnnouncementSeverity.info,
    title: (t) => t.announcements.fixtures.welcome.title,
    message: (t) => t.announcements.fixtures.welcome.message,
  );

  static final Announcement changelog = Announcement(
    id: 'changelog',
    severity: AnnouncementSeverity.success,
    title: (t) => t.announcements.fixtures.changelog.title,
    message: (t) => t.announcements.fixtures.changelog.message,
    actionRoute: 'settings',
  );

  static final Announcement deprecation = Announcement(
    id: 'deprecation',
    severity: AnnouncementSeverity.warning,
    title: (t) => t.announcements.fixtures.deprecation.title,
    message: (t) => t.announcements.fixtures.deprecation.message,
  );

  static final Announcement outage = Announcement(
    id: 'outage',
    severity: AnnouncementSeverity.critical,
    title: (t) => t.announcements.fixtures.outage.title,
    message: (t) => t.announcements.fixtures.outage.message,
  );

  static Announcement forSeverity(AnnouncementSeverity severity) {
    return switch (severity) {
      AnnouncementSeverity.info => welcome,
      AnnouncementSeverity.success => changelog,
      AnnouncementSeverity.warning => deprecation,
      AnnouncementSeverity.critical => outage,
    };
  }

  static final List<Announcement> standard = [
    welcome,
    changelog,
    deprecation,
    outage,
  ];
}
