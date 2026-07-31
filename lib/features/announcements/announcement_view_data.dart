import 'package:forui/forui.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';

part 'announcement_view_data.freezed.dart';

/// Severity of an in-app announcement. Drives the [FAlert] variant + icon via
/// an exhaustive switch in `announcement_banner.dart`.
enum AnnouncementSeverity { info, success, warning, critical }

/// A localized, dismiss-tracked broadcast rendered above the router shell.
/// Title/message resolve lazily through [Translations], keeping the value
/// object free of slang string keys while staying fully typed. The object
/// itself is never persisted — only its [id] joins the dismissed set stored
/// under `announcements.dismissedIds`.
@freezed
abstract class Announcement with _$Announcement {
  const factory Announcement({
    required String id,
    required AnnouncementSeverity severity,
    required String Function(Translations translations) title,
    required String Function(Translations translations) message,
    String? actionRoute,
    @Default(true) bool dismissible,
    DateTime? activeFrom,
    DateTime? activeUntil,
    String? minAppVersion,
    String? maxAppVersion,
  }) = _Announcement;

  const Announcement._();

  /// Stable identifier; joining the dismissed set hides this announcement.
  /// Drives banner styling (FAlert variant + icon) via the exhaustive switch.
  /// Localized title, resolved against the active [Translations].
  /// Localized body, resolved against the active [Translations].
  /// Optional existing named route navigated to via `context.goNamed` when
  /// the CTA is tapped. A plain string — features must not import route
  /// constants.
  /// Whether the dismiss control is offered. Critical broadcasts can pin
  /// themselves with `false` to force a read.
  /// Inclusive lower bound of the active date window (`null` = unbounded past).
  /// Inclusive upper bound of the active date window (`null` = unbounded future).
  /// Minimum app version (inclusive) for this announcement to show. `null`
  /// means no lower bound.
  /// Maximum app version (inclusive) for this announcement to show. `null`
  /// means no upper bound.
  /// Whether [now] falls inside the active date window.
  bool isWithinDateWindow(DateTime now) {
    final from = activeFrom;
    final until = activeUntil;
    if (from != null && now.isBefore(from)) {
      return false;
    }
    if (until != null && now.isAfter(until)) {
      return false;
    }
    return true;
  }

  /// Whether [buildInfo] satisfies the version window. Ungated announcements
  /// (both bounds `null`) are always in window, even before [buildInfo]
  /// resolves; gated announcements are excluded until it is available.
  bool isWithinVersionWindow(AppBuildInfo? buildInfo) {
    final min = minAppVersion;
    final max = maxAppVersion;
    if (min == null && max == null) {
      return true;
    }
    final info = buildInfo;
    if (info == null) {
      return false;
    }
    final app = info.version;
    if (min != null && _compareVersions(app, min) < 0) {
      return false;
    }
    if (max != null && _compareVersions(app, max) > 0) {
      return false;
    }
    return true;
  }
}

/// Compares two dotted version strings (`"1.2.3"`) segment by segment.
/// Missing segments are treated as `0`; non-numeric segments fall back to
/// `0`. Returns `-1`, `0`, or `1`.
int _compareVersions(String a, String b) {
  final pa = a.split('.');
  final pb = b.split('.');
  final longest = pa.length > pb.length ? pa.length : pb.length;
  for (var i = 0; i < longest; i += 1) {
    final ai = i < pa.length ? (int.tryParse(pa[i]) ?? 0) : 0;
    final bi = i < pb.length ? (int.tryParse(pb[i]) ?? 0) : 0;
    if (ai != bi) {
      return ai < bi ? -1 : 1;
    }
  }
  return 0;
}

/// Resolves the first announcement in [announcements] that is not dismissed,
/// inside its date window at [now], and inside its version window for
/// [buildInfo]. List order is priority order.
Announcement? resolveActiveAnnouncement({
  required List<Announcement> announcements,
  required Set<String> dismissedIds,
  required DateTime now,
  AppBuildInfo? buildInfo,
}) {
  for (final announcement in announcements) {
    if (dismissedIds.contains(announcement.id)) {
      continue;
    }
    if (!announcement.isWithinDateWindow(now)) {
      continue;
    }
    if (!announcement.isWithinVersionWindow(buildInfo)) {
      continue;
    }
    return announcement;
  }
  return null;
}

/// Lifecycle of a dismiss interaction. The banner observes
/// [AnnouncementsState.status] to surface a transient toast when persistence
/// fails — the optimistic dismiss rolls back so the banner re-appears.
enum AnnouncementsStatus { idle, dismissFailure }

/// Immutable state published by the announcements controller. Holds the
/// resolved [active] banner and the dismissed id set for observability.
@freezed
abstract class AnnouncementsState with _$AnnouncementsState {
  const factory AnnouncementsState({
    required Announcement? active,
    required Set<String> dismissedIds,
    @Default(AnnouncementsStatus.idle) AnnouncementsStatus status,
  }) = _AnnouncementsState;

  /// The announcement the banner should render, or `null` when nothing is in
  /// window.
  /// Dismissed announcement ids persisted under the `announcements.dismissedIds`
  /// settings key.
}
