import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';

part 'announcement_view_data.freezed.dart';

enum AnnouncementSeverity { info, success, warning, critical }

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

enum AnnouncementsStatus { idle, dismissFailure }

@freezed
abstract class AnnouncementsState with _$AnnouncementsState {
  const factory AnnouncementsState({
    required Announcement? active,
    required Set<String> dismissedIds,
    @Default(AnnouncementsStatus.idle) AnnouncementsStatus status,
  }) = _AnnouncementsState;
}
