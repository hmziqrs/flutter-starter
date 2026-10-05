import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:starter/features/notifications/notification_permission_status.dart';
import 'package:starter/features/notifications/notification_tap.dart';
import 'package:starter/features/notifications/notifications_repository.dart';
import 'package:starter/features/settings/settings_store.dart';
import 'package:starter/infrastructure/logging/app_logger.dart';

part 'notifications_controller.freezed.dart';

enum NotificationsRegistrationState {
  idle,

  registering,

  registered,

  unavailable,

  failed,
}

@Freezed(copyWith: false)
class NotificationsState with _$NotificationsState {
  const NotificationsState({
    this.permission = NotificationPermissionStatus.notRequested,
    this.token,
    this.registration = NotificationsRegistrationState.idle,
  });

  const NotificationsState.defaults()
    : permission = NotificationPermissionStatus.notRequested,
      token = null,
      registration = NotificationsRegistrationState.idle;

  @override
  final NotificationPermissionStatus permission;

  @override
  final String? token;

  @override
  final NotificationsRegistrationState registration;

  bool get isUnavailable => registration == NotificationsRegistrationState.unavailable;

  NotificationsState copyWith({
    NotificationPermissionStatus? permission,
    String? token,
    bool clearToken = false,
    NotificationsRegistrationState? registration,
  }) {
    return NotificationsState(
      permission: permission ?? this.permission,
      token: clearToken ? null : (token ?? this.token),
      registration: registration ?? this.registration,
    );
  }
}

final initialNotificationPermissionProvider = Provider<NotificationPermissionStatus>(
  (ref) => NotificationPermissionStatus.notRequested,
);

final initialNotificationTokenProvider = Provider<String?>((ref) => null);

final notificationsControllerProvider =
    NotifierProvider<NotificationsController, NotificationsState>(NotificationsController.new);

final class NotificationsController extends Notifier<NotificationsState> {
  @override
  NotificationsState build() {
    final initialToken = ref.watch(initialNotificationTokenProvider);
    final seeded = NotificationsState(
      permission: ref.watch(initialNotificationPermissionProvider),
      token: initialToken,
      registration: initialToken == null
          ? NotificationsRegistrationState.idle
          : NotificationsRegistrationState.registered,
    );
    unawaited(_hydrateFromStore(seeded));
    return seeded;
  }

  /// Seeds state from the previous session's [persistedTokenKey] /
  /// [persistedPermissionKey] values so notification state survives a relaunch.
  ///
  /// The store read races anything that mutates state after [build]; the seed
  /// passed in is only replaced when state is still exactly that seed, so a
  /// slower read never clobbers a fresher permission/token change.
  Future<void> _hydrateFromStore(NotificationsState seeded) async {
    final NotificationPermissionStatus? permission;
    final String? token;
    try {
      final store = ref.read(settingsStoreProvider);
      permission = _permissionFromName(await store.readString(persistedPermissionKey));
      final storedToken = await store.readString(persistedTokenKey);
      token = storedToken == null || storedToken.isEmpty ? null : storedToken;
    } on Object catch (error, stackTrace) {
      // A failed read only degrades persistence; the seed stays authoritative.
      ref
          .read(appLoggerProvider)
          .warning('notifications.hydrate failed', error: error, stackTrace: stackTrace);
      return;
    }
    if (!ref.mounted || (permission == null && token == null) || state != seeded) {
      return;
    }
    state = state.copyWith(
      permission: permission,
      token: token,
      registration: token == null ? null : NotificationsRegistrationState.registered,
    );
  }

  static NotificationPermissionStatus? _permissionFromName(String? name) =>
      name == null ? null : NotificationPermissionStatus.values.asNameMap()[name];

  // Persistence is a cross-launch cache: the in-memory state (OS truth from
  // this session) stays authoritative when a write fails.
  Future<void> _persistPermission(NotificationPermissionStatus status) =>
      _persist((store) => store.writeString(persistedPermissionKey, status.name));

  Future<void> _persistToken(String? token) => _persist(
    (store) => token == null
        ? store.remove(persistedTokenKey)
        : store.writeString(persistedTokenKey, token),
  );

  Future<void> _persist(Future<void> Function(SettingsStore store) write) async {
    try {
      await write(ref.read(settingsStoreProvider));
    } on Object catch (error, stackTrace) {
      ref
          .read(appLoggerProvider)
          .warning('notifications.persist failed', error: error, stackTrace: stackTrace);
    }
  }

  Future<NotificationPermissionStatus> requestPermission({bool provisional = false}) async {
    final previous = state;
    final repository = ref.read(notificationsRepositoryProvider);
    try {
      final status = await repository.requestPermission(provisional: provisional);
      state = previous.copyWith(permission: status);
      await _persistPermission(status);
      return status;
    } on NotificationsException {
      state = previous.copyWith(registration: NotificationsRegistrationState.failed);
      rethrow;
    }
  }

  Future<void> register({bool provisional = false}) async {
    state = state.copyWith(registration: NotificationsRegistrationState.registering);
    final repository = ref.read(notificationsRepositoryProvider);
    if (state.permission == NotificationPermissionStatus.notRequested) {
      try {
        final status = await repository.requestPermission(provisional: provisional);
        state = state.copyWith(permission: status);
        await _persistPermission(status);
      } on NotificationsException catch (error) {
        state = state.copyWith(registration: _landFromException(error));
        return;
      }
    }
    try {
      final token = await repository.registerToken();
      if (token == null) {
        state = state.copyWith(
          clearToken: true,
          registration: NotificationsRegistrationState.idle,
        );
        await _persistToken(null);
        return;
      }
      state = state.copyWith(token: token, registration: NotificationsRegistrationState.registered);
      await _persistToken(token);
    } on NotificationsException catch (error) {
      state = state.copyWith(registration: _landFromException(error));
    }
  }

  static NotificationsRegistrationState _landFromException(NotificationsException error) {
    return switch (error.kind) {
      NotificationsFailureKind.notConnected => NotificationsRegistrationState.unavailable,
      NotificationsFailureKind.denied => NotificationsRegistrationState.failed,
      NotificationsFailureKind.unknown => NotificationsRegistrationState.failed,
    };
  }

  Future<void> unregister() async {
    final previousToken = state.token;
    if (previousToken == null) {
      return;
    }
    state = state.copyWith(clearToken: true, registration: NotificationsRegistrationState.idle);
    await _persistToken(null);
    try {
      final repository = ref.read(notificationsRepositoryProvider);
      await repository.unregisterToken(previousToken);
    } on NotificationsException {}
  }
}

/// SettingsStore keys backing the Contract's persistence claim: one key each
/// for the last-known permission status and the registered delivery token.
const String persistedPermissionKey = 'notifications.permission';
const String persistedTokenKey = 'notifications.token';

final notificationTapQueueProvider = NotifierProvider<NotificationTapQueue, List<NotificationTap>>(
  NotificationTapQueue.new,
);

final class NotificationTapQueue extends Notifier<List<NotificationTap>> {
  StreamSubscription<NotificationTap>? _subscription;

  @override
  List<NotificationTap> build() {
    final repository = ref.watch(notificationsRepositoryProvider);
    _subscription = repository.onNotificationTap.listen(_enqueue);
    ref.onDispose(() {
      unawaited(_subscription?.cancel());
      _subscription = null;
    });
    return const <NotificationTap>[];
  }

  void _enqueue(NotificationTap tap) {
    state = [...state, tap];
  }

  void consume(NotificationTap tap) {
    if (!state.contains(tap)) {
      return;
    }
    state = state.where((entry) => entry != tap).toList(growable: false);
  }

  void clear() {
    if (state.isEmpty) return;
    state = const <NotificationTap>[];
  }
}
