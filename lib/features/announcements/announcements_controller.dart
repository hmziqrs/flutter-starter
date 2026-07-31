import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/announcements/announcement_fixtures.dart';
import 'package:starter/features/announcements/announcement_view_data.dart';
import 'package:starter/features/settings/settings_store.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';

abstract final class DismissedAnnouncements {
  static const String key = 'announcements.dismissedIds';

  static String encode(Set<String> ids) {
    final list = ids.toList()..sort();
    return jsonEncode(list);
  }

  static Set<String> decode(String? stored) {
    if (stored == null || stored.isEmpty) {
      return <String>{};
    }
    try {
      final decoded = jsonDecode(stored);
      if (decoded is! List) {
        return <String>{};
      }
      final ids = <String>{};
      for (final entry in decoded) {
        if (entry is String) {
          ids.add(entry);
        }
      }
      return ids;
    } on FormatException {
      return <String>{};
    }
  }
}

final initialDismissedAnnouncementIdsProvider = Provider<Set<String>>(
  (ref) => const <String>{},
);

final announcementsFixturesProvider = Provider<List<Announcement>>(
  (ref) => AnnouncementFixtures.standard,
);

final appBuildInfoProvider = Provider<AppBuildInfo?>((ref) => null);

final announcementsControllerProvider =
    NotifierProvider<AnnouncementsController, AnnouncementsState>(
      AnnouncementsController.new,
    );

final class AnnouncementsController extends Notifier<AnnouncementsState> {
  @override
  AnnouncementsState build() {
    final announcements = ref.watch(announcementsFixturesProvider);
    final dismissed = ref.watch(initialDismissedAnnouncementIdsProvider);
    final buildInfo = ref.watch(appBuildInfoProvider);
    return AnnouncementsState(
      active: resolveActiveAnnouncement(
        announcements: announcements,
        dismissedIds: dismissed,
        buildInfo: buildInfo,
        now: DateTime.now(),
      ),
      dismissedIds: dismissed,
    );
  }

  Future<void> dismiss(String id) async {
    final previous = state;
    final nextDismissed = {...previous.dismissedIds, id};
    final announcements = ref.read(announcementsFixturesProvider);
    final buildInfo = ref.read(appBuildInfoProvider);
    state = AnnouncementsState(
      active: resolveActiveAnnouncement(
        announcements: announcements,
        dismissedIds: nextDismissed,
        buildInfo: buildInfo,
        now: DateTime.now(),
      ),
      dismissedIds: nextDismissed,
    );
    final store = ref.read(settingsStoreProvider);
    try {
      await store.writeString(
        DismissedAnnouncements.key,
        DismissedAnnouncements.encode(nextDismissed),
      );
    } on Object {
      state = previous.copyWith(status: AnnouncementsStatus.dismissFailure);
    }
  }

  void acknowledgeFailure() {
    if (state.status == AnnouncementsStatus.dismissFailure) {
      state = state.copyWith(status: AnnouncementsStatus.idle);
    }
  }
}
