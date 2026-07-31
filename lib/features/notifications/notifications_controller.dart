import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:starter/features/notifications/notification_permission_status.dart';
import 'package:starter/features/notifications/notification_tap.dart';
import 'package:starter/features/notifications/notifications_repository.dart';

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
  NotificationsState build() => NotificationsState(
    permission: ref.watch(initialNotificationPermissionProvider),
    token: ref.watch(initialNotificationTokenProvider),
    registration: ref.watch(initialNotificationTokenProvider) == null
        ? NotificationsRegistrationState.idle
        : NotificationsRegistrationState.registered,
  );

  Future<NotificationPermissionStatus> requestPermission({bool provisional = false}) async {
    final previous = state;
    final repository = ref.read(notificationsRepositoryProvider);
    try {
      final status = await repository.requestPermission(provisional: provisional);
      state = previous.copyWith(permission: status);
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
        return;
      }
      state = state.copyWith(token: token, registration: NotificationsRegistrationState.registered);
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
    try {
      final repository = ref.read(notificationsRepositoryProvider);
      await repository.unregisterToken(previousToken);
    } on NotificationsException {
      // Best-effort: local state already cleared.
    }
  }
}

/// The token is a delivery address, not a credential, so plaintext is appropriate.
const String persistedPermissionKey = 'notifications.permission';
const String persistedTokenKey = 'notifications.token';

/// The cold-start tap must be captured before `_AppViewState` mounts its drain listener.
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
