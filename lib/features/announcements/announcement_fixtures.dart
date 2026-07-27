import 'package:starter/features/announcements/announcement_view_data.dart';

/// Compile-time announcement fixtures. The default feed ([standard]) is the
/// production broadcast; the named single-severity fixtures double as
/// dev-gallery templates (via [forSeverity]) and ready-to-enable copy.
///
/// Always-in-window by design — version/date gating is exercised by the
/// controller tests with constructed [Announcement] instances, not by the
/// default feed. A consumer authors a real feed by replacing [standard] (or by
/// wiring a deferred `AnnouncementsSource` override later — see the feature
/// spec's backend-free stance).
abstract final class AnnouncementFixtures {
  /// Friendly first-launch welcome (info). The first item in [standard], so it
  /// is what the banner shows until dismissed.
  static final Announcement welcome = Announcement(
    id: 'welcome',
    severity: AnnouncementSeverity.info,
    title: (t) => t.announcements.fixtures.welcome.title,
    message: (t) => t.announcements.fixtures.welcome.message,
  );

  /// "New in this version" (success). Carries a CTA into the settings route.
  static final Announcement changelog = Announcement(
    id: 'changelog',
    severity: AnnouncementSeverity.success,
    title: (t) => t.announcements.fixtures.changelog.title,
    message: (t) => t.announcements.fixtures.changelog.message,
    // Plain route name — features must not import route constants. Matches the
    // existing `settings` named route; the banner resolves it via goNamed.
    actionRoute: 'settings',
  );

  /// Soft deprecation nudge (warning).
  static final Announcement deprecation = Announcement(
    id: 'deprecation',
    severity: AnnouncementSeverity.warning,
    title: (t) => t.announcements.fixtures.deprecation.title,
    message: (t) => t.announcements.fixtures.deprecation.message,
  );

  /// Ongoing outage (critical). Pinned with `dismissible: false` to demonstrate
  /// the must-read broadcast path.
  static final Announcement outage = Announcement(
    id: 'outage',
    severity: AnnouncementSeverity.critical,
    title: (t) => t.announcements.fixtures.outage.title,
    message: (t) => t.announcements.fixtures.outage.message,
    dismissible: false,
  );

  /// Returns the named fixture for [severity]. Exhaustive over
  /// [AnnouncementSeverity]; adding a severity is a compile error here until a
  /// fixture is supplied.
  static Announcement forSeverity(AnnouncementSeverity severity) {
    return switch (severity) {
      AnnouncementSeverity.info => welcome,
      AnnouncementSeverity.success => changelog,
      AnnouncementSeverity.warning => deprecation,
      AnnouncementSeverity.critical => outage,
    };
  }

  /// Production default feed. Ordered least-alarming first so
  /// [resolveActiveAnnouncement] surfaces a friendly banner on first launch and
  /// cycles through severities as the user dismisses each. The critical
  /// `outage` is last and non-dismissible, so it appears only after the first
  /// three are dismissed.
  static final List<Announcement> standard = [
    welcome,
    changelog,
    deprecation,
    outage,
  ];
}
