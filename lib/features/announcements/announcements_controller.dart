import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/announcements/announcement_fixtures.dart';
import 'package:starter/features/announcements/announcement_view_data.dart';
import 'package:starter/features/settings/settings_store.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';

/// Single [SettingsStore] key holding the JSON-encoded dismissed-announcement
/// id list: a typed encode/decode helper over one string value, tolerant of
/// malformed storage (treated as "nothing dismissed" rather than throwing).
abstract final class DismissedAnnouncements {
  static const String key = 'announcements.dismissedIds';

  /// Encodes [ids] as a sorted JSON array string.
  static String encode(Set<String> ids) {
    final list = ids.toList()..sort();
    return jsonEncode(list);
  }

  /// Decodes a stored JSON array string back into a set of ids. `null`, empty,
  /// malformed, or non-string entries yield an empty set — never throws.
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
      // Narrow each entry rather than casting the whole list, dropping any
      // non-string junk defensively.
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

/// Cold-start seed for the dismissed set. The composition root pre-loads the
/// persisted JSON via [DismissedAnnouncements] and overrides this with the
/// round-tripped set, so the controller resolves [AnnouncementsState.active]
/// synchronously on the first frame.
final initialDismissedAnnouncementIdsProvider = Provider<Set<String>>(
  (ref) => const <String>{},
);

/// The static announcement feed. Defaults to [AnnouncementFixtures.standard];
/// tests and dev-gallery previews override with a single-severity list.
final announcementsFixturesProvider = Provider<List<Announcement>>(
  (ref) => AnnouncementFixtures.standard,
);

/// The installed build, used for version-window filtering. A synchronous
/// value the composition root pre-loads and overrides — a `FutureProvider`
/// here would rebuild the controller on resolve and overwrite an in-flight
/// dismiss with the cold-start seed. The default `null` keeps version-gated
/// fixtures hidden until the override lands; ungated fixtures resolve
/// `active` immediately.
final appBuildInfoProvider = Provider<AppBuildInfo?>((ref) => null);

final announcementsControllerProvider =
    NotifierProvider<AnnouncementsController, AnnouncementsState>(
      AnnouncementsController.new,
    );

/// Publishes the active announcement (filtered by dismissed set + version via
/// [AppBuildInfo] + date window) and persists dismissals under
/// [DismissedAnnouncements.key].
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

  /// Optimistically hides [id] and persists the new dismissed set under
  /// [DismissedAnnouncements.key]. On persistence failure the previous state
  /// rolls back (the banner re-appears) and `status` flips to
  /// `dismissFailure`; the banner surfaces a toast so the failure is never
  /// silently swallowed.
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
      // Roll back the optimistic hide and flag the failure; the banner observes
      // the transition and shows a transient toast, then clears it.
      state = previous.copyWith(status: AnnouncementsStatus.dismissFailure);
    }
  }

  /// Clears a transient [AnnouncementsStatus.dismissFailure] after the banner
  /// has surfaced its toast, so the same failure can re-fire next time.
  void acknowledgeFailure() {
    if (state.status == AnnouncementsStatus.dismissFailure) {
      state = state.copyWith(status: AnnouncementsStatus.idle);
    }
  }
}
