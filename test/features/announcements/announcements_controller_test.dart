import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/announcements/announcement_fixtures.dart';
import 'package:starter/features/announcements/announcement_view_data.dart';
import 'package:starter/features/announcements/announcements_controller.dart';
import 'package:starter/features/settings/in_memory_settings_store.dart';
import 'package:starter/features/settings/settings_store.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';

Announcement _announcement({
  required String id,
  AnnouncementSeverity severity = AnnouncementSeverity.info,
  String Function(Translations translations)? title,
  String Function(Translations translations)? message,
  bool dismissible = true,
  String? actionRoute,
  DateTime? activeFrom,
  DateTime? activeUntil,
  String? minAppVersion,
  String? maxAppVersion,
}) {
  return Announcement(
    id: id,
    severity: severity,
    title: title ?? (_) => id,
    message: message ?? (_) => id,
    dismissible: dismissible,
    actionRoute: actionRoute,
    activeFrom: activeFrom,
    activeUntil: activeUntil,
    minAppVersion: minAppVersion,
    maxAppVersion: maxAppVersion,
  );
}

void main() {
  group('resolveActiveAnnouncement', () {
    final now = DateTime.utc(2026, 7, 27, 12);
    const buildInfo = AppBuildInfo(version: '1.0.0', buildNumber: '1');

    test('returns the first non-dismissed fixture in priority order', () {
      final active = resolveActiveAnnouncement(
        announcements: AnnouncementFixtures.standard,
        dismissedIds: const <String>{},
        buildInfo: buildInfo,
        now: now,
      );
      expect(active?.id, 'welcome');
    });

    test('skips dismissed ids and surfaces the next in priority order', () {
      final active = resolveActiveAnnouncement(
        announcements: AnnouncementFixtures.standard,
        dismissedIds: const <String>{'welcome', 'changelog'},
        buildInfo: buildInfo,
        now: now,
      );
      expect(active?.id, 'deprecation');
    });

    test('returns null when every announcement is dismissed', () {
      final active = resolveActiveAnnouncement(
        announcements: AnnouncementFixtures.standard,
        dismissedIds: const <String>{'welcome', 'changelog', 'deprecation', 'outage'},
        buildInfo: buildInfo,
        now: now,
      );
      expect(active, isNull);
    });

    test('date window excludes not-yet-active and expired announcements', () {
      final future = _announcement(
        id: 'future',
        activeFrom: now.add(const Duration(days: 1)),
      );
      final expired = _announcement(
        id: 'expired',
        activeUntil: now.subtract(const Duration(days: 1)),
      );
      final current = _announcement(id: 'current');
      final active = resolveActiveAnnouncement(
        announcements: [future, expired, current],
        dismissedIds: const <String>{},
        buildInfo: buildInfo,
        now: now,
      );
      expect(active?.id, 'current');
    });

    test('date window honors inclusive boundaries', () {
      final bounded = _announcement(
        id: 'bounded',
        activeFrom: now,
        activeUntil: now,
      );
      final active = resolveActiveAnnouncement(
        announcements: [bounded],
        dismissedIds: const <String>{},
        buildInfo: buildInfo,
        now: now,
      );
      expect(active?.id, 'bounded');
    });

    test('version window: min excludes older builds, max excludes newer', () {
      final tooOldForMin = _announcement(id: 'min', minAppVersion: '1.5.0');
      final tooNewForMax = _announcement(id: 'max', maxAppVersion: '0.9.0');
      final inRange = _announcement(
        id: 'range',
        minAppVersion: '0.5.0',
        maxAppVersion: '2.0.0',
      );
      final active = resolveActiveAnnouncement(
        announcements: [tooOldForMin, tooNewForMax, inRange],
        dismissedIds: const <String>{},
        buildInfo: buildInfo,
        now: now,
      );
      expect(active?.id, 'range');
    });

    test('version window: ungated passes even before build info resolves', () {
      final ungated = _announcement(id: 'ungated');
      // buildInfo is intentionally omitted (defaults to null): exercises the
      // pre-resolution path where PackageInfo has not loaded yet.
      final active = resolveActiveAnnouncement(
        announcements: [ungated],
        dismissedIds: const <String>{},
        now: now,
      );
      expect(active?.id, 'ungated');
    });

    test('version window: gated announcements are excluded until build info loads', () {
      final gated = _announcement(id: 'gated', minAppVersion: '1.0.0');
      // buildInfo omitted (null): a gated announcement must not flash before
      // the version check completes.
      final active = resolveActiveAnnouncement(
        announcements: [gated],
        dismissedIds: const <String>{},
        now: now,
      );
      expect(active, isNull);
    });

    test('version comparison is numeric, not lexical', () {
      // "1.10.0" must be greater than "1.2.0" (lexical would order them wrong).
      final gated = _announcement(id: 'gated', maxAppVersion: '1.2.0');
      final active = resolveActiveAnnouncement(
        announcements: [gated],
        dismissedIds: const <String>{},
        buildInfo: const AppBuildInfo(version: '1.10.0', buildNumber: '1'),
        now: now,
      );
      expect(active, isNull);
    });
  });

  group('DismissedAnnouncements', () {
    test('encode round-trips through decode preserving the set', () {
      final encoded = DismissedAnnouncements.encode(<String>{'c', 'a', 'b'});
      expect(encoded, '["a","b","c"]');
      expect(DismissedAnnouncements.decode(encoded), <String>{'a', 'b', 'c'});
    });

    test('decode tolerates null, empty, malformed, and non-string payloads', () {
      expect(DismissedAnnouncements.decode(null), isEmpty);
      expect(DismissedAnnouncements.decode(''), isEmpty);
      expect(DismissedAnnouncements.decode('not json'), isEmpty);
      expect(DismissedAnnouncements.decode('42'), isEmpty);
      // Non-string entries are dropped, string entries are kept.
      expect(DismissedAnnouncements.decode('["a", 1, true, "b"]'), <String>{'a', 'b'});
    });
  });

  group('AnnouncementsController', () {
    ProviderContainer buildContainer({
      required SettingsStore store,
      Set<String> initialDismissed = const <String>{},
    }) {
      final container = ProviderContainer(
        overrides: [
          settingsStoreProvider.overrideWithValue(store),
          announcementsFixturesProvider.overrideWithValue(AnnouncementFixtures.standard),
          initialDismissedAnnouncementIdsProvider.overrideWithValue(initialDismissed),
          appBuildInfoProvider.overrideWithValue(
            const AppBuildInfo(version: '1.0.0', buildNumber: '1'),
          ),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('publishes the first fixture as active on a clean seed', () {
      final container = buildContainer(store: InMemorySettingsStore());
      expect(
        container.read(announcementsControllerProvider).active?.id,
        'welcome',
      );
    });

    test('cold-start seed restores the dismissed set and hides prior banners', () {
      final container = buildContainer(
        store: InMemorySettingsStore(),
        initialDismissed: const <String>{'welcome'},
      );
      expect(
        container.read(announcementsControllerProvider).active?.id,
        'changelog',
      );
    });

    test('dismiss optimistically hides the id and persists the JSON list', () async {
      final store = InMemorySettingsStore();
      final container = buildContainer(store: store);

      await container.read(announcementsControllerProvider.notifier).dismiss('welcome');

      expect(
        container.read(announcementsControllerProvider).active?.id,
        'changelog',
      );
      final stored = await store.readString(DismissedAnnouncements.key);
      expect(DismissedAnnouncements.decode(stored), <String>{'welcome'});
    });

    test('dismiss round-trips: a second controller rebuilds from persisted state', () async {
      final store = InMemorySettingsStore();
      final first = buildContainer(store: store);
      await first.read(announcementsControllerProvider.notifier).dismiss('welcome');
      await first.read(announcementsControllerProvider.notifier).dismiss('changelog');
      final persisted = DismissedAnnouncements.decode(
        await store.readString(DismissedAnnouncements.key),
      );

      // Simulate a cold start: a fresh container seeded from the persisted set.
      final second = buildContainer(store: store, initialDismissed: persisted);
      expect(
        second.read(announcementsControllerProvider).active?.id,
        'deprecation',
      );
    });

    test('persistence failure rolls back active and flags dismissFailure', () async {
      final store = InMemorySettingsStore()..failWrites = true;
      final container = buildContainer(store: store);

      final before = container.read(announcementsControllerProvider);
      expect(before.active?.id, 'welcome');

      await container.read(announcementsControllerProvider.notifier).dismiss('welcome');

      final after = container.read(announcementsControllerProvider);
      expect(after.active?.id, 'welcome'); // optimistic hide rolled back
      expect(after.status, AnnouncementsStatus.dismissFailure);
    });

    test('acknowledgeFailure clears the dismissFailure status', () async {
      final store = InMemorySettingsStore()..failWrites = true;
      final container = buildContainer(store: store);

      await container.read(announcementsControllerProvider.notifier).dismiss('welcome');
      expect(
        container.read(announcementsControllerProvider).status,
        AnnouncementsStatus.dismissFailure,
      );

      container.read(announcementsControllerProvider.notifier).acknowledgeFailure();
      expect(
        container.read(announcementsControllerProvider).status,
        AnnouncementsStatus.idle,
      );
    });
  });
}
