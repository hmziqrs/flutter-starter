import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/notifications/in_memory_notifications_repository.dart';
import 'package:starter/features/notifications/noop_notifications_repository.dart';
import 'package:starter/features/notifications/notification_permission_status.dart';
import 'package:starter/features/notifications/notification_tap.dart';
import 'package:starter/features/notifications/notifications_controller.dart';
import 'package:starter/features/notifications/notifications_repository.dart';
import 'package:starter/features/settings/in_memory_settings_store.dart';
import 'package:starter/features/settings/settings_store.dart';

void main() {
  group('NotificationsController', () {
    group('with Noop default (no-backend)', () {
      test('register surfaces unavailable (never fakes a registered token)', () async {
        final container = _buildContainer(repository: const NoopNotificationsRepository());
        addTearDown(container.dispose);
        await container.read(notificationsControllerProvider.notifier).register();
        final state = container.read(notificationsControllerProvider);
        expect(state.registration, NotificationsRegistrationState.unavailable);
        expect(state.token, isNull);
        expect(state.isUnavailable, isTrue);
      });

      test('permission stays denied after a no-backend register', () async {
        final container = _buildContainer(repository: const NoopNotificationsRepository());
        addTearDown(container.dispose);
        await container.read(notificationsControllerProvider.notifier).register();
        expect(
          container.read(notificationsControllerProvider).permission,
          NotificationPermissionStatus.denied,
        );
      });
    });

    group('with InMemory repository (happy path)', () {
      test('register transitions through registering -> registered', () async {
        final repository = InMemoryNotificationsRepository();
        final container = _buildContainer(repository: repository);
        addTearDown(container.dispose);
        await container.read(notificationsControllerProvider.notifier).register();
        final state = container.read(notificationsControllerProvider);
        expect(state.registration, NotificationsRegistrationState.registered);
        expect(state.permission, NotificationPermissionStatus.granted);
        expect(state.token, isNotNull);
        addTearDown(repository.dispose);
      });

      test('unregister clears the token and lands in idle', () async {
        final repository = InMemoryNotificationsRepository(
          permission: NotificationPermissionStatus.granted,
          token: 'seeded-token',
        );
        final container = _buildContainer(repository: repository);
        addTearDown(container.dispose);
        await container.read(notificationsControllerProvider.notifier).register();
        expect(container.read(notificationsControllerProvider).token, isNotNull);
        await container.read(notificationsControllerProvider.notifier).unregister();
        final state = container.read(notificationsControllerProvider);
        expect(state.token, isNull);
        expect(state.registration, NotificationsRegistrationState.idle);
        addTearDown(repository.dispose);
      });
    });

    group('requestPermission', () {
      test('persists granted status on the happy path', () async {
        final repository = InMemoryNotificationsRepository();
        final store = InMemorySettingsStore();
        final container = _buildContainer(repository: repository, store: store);
        addTearDown(container.dispose);
        final status = await container
            .read(notificationsControllerProvider.notifier)
            .requestPermission();
        expect(status, NotificationPermissionStatus.granted);
        expect(
          container.read(notificationsControllerProvider).permission,
          NotificationPermissionStatus.granted,
        );
        expect(
          store.snapshot[persistedPermissionKey],
          NotificationPermissionStatus.granted.name,
        );
        addTearDown(repository.dispose);
      });

      test('lands in failed when the repository throws', () async {
        final repository = InMemoryNotificationsRepository(
          permission: NotificationPermissionStatus.denied,
        );
        final container = _buildContainer(repository: repository);
        addTearDown(container.dispose);
        await container.read(notificationsControllerProvider.notifier).register();
        expect(
          container.read(notificationsControllerProvider).registration,
          NotificationsRegistrationState.failed,
        );
        addTearDown(repository.dispose);
      });
    });

    group('SettingsStore persistence', () {
      test('register persists the permission and token under the declared keys', () async {
        final repository = InMemoryNotificationsRepository();
        final store = InMemorySettingsStore();
        final container = _buildContainer(repository: repository, store: store);
        addTearDown(container.dispose);
        await container.read(notificationsControllerProvider.notifier).register();
        expect(
          store.snapshot[persistedPermissionKey],
          NotificationPermissionStatus.granted.name,
        );
        expect(
          store.snapshot[persistedTokenKey],
          container.read(notificationsControllerProvider).token,
        );
        addTearDown(repository.dispose);
      });

      test('a relaunch seeds state from the persisted permission and token', () async {
        final store = InMemorySettingsStore(
          seed: {
            persistedPermissionKey: NotificationPermissionStatus.provisional.name,
            persistedTokenKey: 'persisted-token',
          },
        );
        final repository = InMemoryNotificationsRepository();
        final container = _buildContainer(repository: repository, store: store);
        addTearDown(container.dispose);
        container.read(notificationsControllerProvider);
        await Future<void>.delayed(Duration.zero);
        final state = container.read(notificationsControllerProvider);
        expect(state.token, 'persisted-token');
        expect(state.permission, NotificationPermissionStatus.provisional);
        expect(state.registration, NotificationsRegistrationState.registered);
        addTearDown(repository.dispose);
      });

      test('a slow hydration read never clobbers a fresher permission/token change', () async {
        final store = _SlowReadSettingsStore(
          seed: {
            persistedPermissionKey: NotificationPermissionStatus.provisional.name,
            persistedTokenKey: 'stale-persisted-token',
          },
        );
        final repository = InMemoryNotificationsRepository();
        final container = _buildContainer(repository: repository, store: store);
        addTearDown(container.dispose);
        // build() kicks off hydration, which parks on the store's gated reads.
        container.read(notificationsControllerProvider);
        // While that read is still pending, a real registration lands fresher
        // OS truth than whatever the previous session persisted.
        await container.read(notificationsControllerProvider.notifier).register();
        final fresh = container.read(notificationsControllerProvider);
        expect(fresh.permission, NotificationPermissionStatus.granted);
        expect(fresh.token, isNot('stale-persisted-token'));

        store.releaseReads();
        for (var attempt = 0; attempt < 4; attempt += 1) {
          await Future<void>.delayed(Duration.zero);
        }

        final state = container.read(notificationsControllerProvider);
        expect(state.permission, NotificationPermissionStatus.granted);
        expect(state.token, fresh.token);
        expect(state.registration, NotificationsRegistrationState.registered);
        addTearDown(repository.dispose);
      });

      test('unregister removes the persisted token but keeps the permission', () async {
        final repository = InMemoryNotificationsRepository(
          permission: NotificationPermissionStatus.granted,
          token: 'seeded-token',
        );
        final store = InMemorySettingsStore();
        final container = _buildContainer(repository: repository, store: store);
        addTearDown(container.dispose);
        await container.read(notificationsControllerProvider.notifier).register();
        await container.read(notificationsControllerProvider.notifier).unregister();
        expect(store.snapshot.containsKey(persistedTokenKey), isFalse);
        expect(
          store.snapshot[persistedPermissionKey],
          NotificationPermissionStatus.granted.name,
        );
        addTearDown(repository.dispose);
      });
    });
  });

  group('NotificationTapQueue', () {
    test('cold-start tap is buffered before any router drain subscribes', () async {
      final repository = InMemoryNotificationsRepository();
      final container = _buildContainer(repository: repository);
      addTearDown(container.dispose);
      container.read(notificationTapQueueProvider);
      const tap = NotificationTap(targetRoute: 'home');
      repository.deliverTap(tap);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(notificationTapQueueProvider), [tap]);
      addTearDown(repository.dispose);
    });

    test('taps enqueue in arrival order', () async {
      final repository = InMemoryNotificationsRepository();
      final container = _buildContainer(repository: repository);
      addTearDown(container.dispose);
      container.read(notificationTapQueueProvider);
      const first = NotificationTap(targetRoute: 'home');
      const second = NotificationTap(targetRoute: 'settings');
      repository
        ..deliverTap(first)
        ..deliverTap(second);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(notificationTapQueueProvider), [first, second]);
      addTearDown(repository.dispose);
    });

    test('consume removes the tap and keeps the rest', () async {
      final repository = InMemoryNotificationsRepository();
      final container = _buildContainer(repository: repository);
      addTearDown(container.dispose);
      container.read(notificationTapQueueProvider);
      const first = NotificationTap(targetRoute: 'home');
      const second = NotificationTap(targetRoute: 'settings');
      repository
        ..deliverTap(first)
        ..deliverTap(second);
      await Future<void>.delayed(Duration.zero);
      container.read(notificationTapQueueProvider.notifier).consume(first);
      expect(container.read(notificationTapQueueProvider), [second]);
      addTearDown(repository.dispose);
    });

    test('clear empties the queue', () async {
      final repository = InMemoryNotificationsRepository();
      final container = _buildContainer(repository: repository);
      addTearDown(container.dispose);
      container.read(notificationTapQueueProvider);
      const tap = NotificationTap(targetRoute: 'home');
      repository.deliverTap(tap);
      await Future<void>.delayed(Duration.zero);
      container.read(notificationTapQueueProvider.notifier).clear();
      expect(container.read(notificationTapQueueProvider), isEmpty);
      addTearDown(repository.dispose);
    });
  });
}

ProviderContainer _buildContainer({
  required NotificationsRepository repository,
  SettingsStore? store,
}) {
  return ProviderContainer(
    overrides: [
      notificationsRepositoryProvider.overrideWithValue(repository),
      settingsStoreProvider.overrideWithValue(store ?? InMemorySettingsStore()),
    ],
  );
}

/// A [SettingsStore] whose reads serve a frozen snapshot of the seed and park
/// on a [Completer], so a test can land a fresher permission/token change while
/// the controller's hydration read is still in flight, then let the read finish
/// and assert the previous session's values did not clobber the fresh ones.
final class _SlowReadSettingsStore implements SettingsStore {
  _SlowReadSettingsStore({required Map<String, String> seed})
    : _seeded = Map.unmodifiable({...seed}),
      _values = {...seed};

  final Map<String, String> _seeded;
  final Map<String, String> _values;
  final Completer<void> _reads = Completer<void>();

  void releaseReads() => _reads.complete();

  @override
  Future<String?> readString(String key) async {
    await _reads.future;
    return _seeded[key];
  }

  @override
  Future<void> remove(String key) async {
    _values.remove(key);
  }

  @override
  Future<void> writeString(String key, String value) async {
    _values[key] = value;
  }
}
