import 'dart:async';

// Doc cross-references to sibling-class names in the feature package are
// intentional `comment_references`.
// ignore_for_file: comment_references

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/notifications/notification_permission_status.dart';
import 'package:starter/features/notifications/notification_tap.dart';
import 'package:starter/features/notifications/notifications_repository.dart';

/// Coarse lifecycle of the token-registration state machine, surfaced on the
/// rationale sheet and diagnostics page without leaking the underlying
/// exception.
enum NotificationsRegistrationState {
  /// No registration attempt has been made yet (the default).
  idle,

  /// A `registerToken` call is in flight.
  registering,

  /// A token was successfully registered with the backend.
  registered,

  /// The registration path surfaced [NotificationsException.notConnected].
  unavailable,

  /// A non-notConnected failure (denied / unknown). The rationale sheet
  /// surfaces `notifications.disabled` or the generic error copy.
  failed,
}

/// Immutable, value-equal snapshot of the notifications controller state.
@immutable
final class NotificationsState {
  const NotificationsState({
    this.permission = NotificationPermissionStatus.notRequested,
    this.token,
    this.registration = NotificationsRegistrationState.idle,
  });

  const NotificationsState.defaults()
    : permission = NotificationPermissionStatus.notRequested,
      token = null,
      registration = NotificationsRegistrationState.idle;

  final NotificationPermissionStatus permission;

  /// The currently registered backend token (or `null`). Never logged raw —
  /// the [LogRedactor] scrubs token-shaped strings.
  final String? token;

  final NotificationsRegistrationState registration;

  /// True when the rationale sheet should surface `notifications.disabled` /
  /// `common.notConnected`.
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationsState &&
        other.permission == permission &&
        other.token == token &&
        other.registration == registration;
  }

  @override
  int get hashCode => Object.hash(permission, token, registration);
}

/// Cold-start seed for the persisted permission status. Overridden at the
/// `ProviderScope` so the controller resolves synchronously on first frame.
final initialNotificationPermissionProvider = Provider<NotificationPermissionStatus>(
  (ref) => NotificationPermissionStatus.notRequested,
);

/// Cold-start seed for the persisted registered token, if any.
final initialNotificationTokenProvider = Provider<String?>((ref) => null);

/// Handwritten Riverpod `Notifier<NotificationsState>` for the notifications
/// permission + token-registration state machine. Optimistic state
/// transitions with typed exceptions surfaced as
/// [NotificationsRegistrationState.unavailable] rather than faking success.
/// Permission status and the last-registered token are persisted under
/// [persistedPermissionKey] / [persistedTokenKey].
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

  /// Requests notification authorization from the OS via the repository. A
  /// failure rolls back to the previous value and lands the registration
  /// state in [NotificationsRegistrationState.failed].
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

  /// Requests permission if needed, then registers the token. The Noop
  /// default throws [NotificationsException.notConnected] inside
  /// `registerToken`; the controller catches it and lands the state in
  /// [NotificationsRegistrationState.unavailable]. Permission gating is
  /// delegated to the repository: `registerToken` throws a typed exception
  /// when authorization is missing (`denied`) or no backend is reachable
  /// (`notConnected`) — the exception kind, not the controller's local
  /// permission view, drives the final landing state.
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

  /// Unregisters the current token (best-effort). Local state clears
  /// regardless of whether the backend call succeeds, so a network failure
  /// during opt-out never strands the user in a "registered" state.
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

/// `SettingsStore` keys persisting the notifications state across launches.
/// The token is a delivery address, not a credential, so `SettingsStore`
/// (plaintext) is appropriate.
const String persistedPermissionKey = 'notifications.permission';
const String persistedTokenKey = 'notifications.token';

/// Handwritten Riverpod `Notifier<List<NotificationTap>>` that buffers
/// notification taps (foreground + cold-start) in arrival order until the
/// router drains them. Subscribes to
/// [NotificationsRepository.onNotificationTap] inside [build] so the
/// subscription is alive the moment the provider is first read, capturing the
/// cold-start tap before `_AppViewState` mounts its drain listener.
final notificationTapQueueProvider = NotifierProvider<NotificationTapQueue, List<NotificationTap>>(
  NotificationTapQueue.new,
);

final class NotificationTapQueue extends Notifier<List<NotificationTap>> {
  StreamSubscription<NotificationTap>? _subscription;

  @override
  List<NotificationTap> build() {
    final repository = ref.watch(notificationsRepositoryProvider);
    // Subscribe immediately so a foreground tap arriving between queue
    // creation and the first read is still captured.
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

  /// Removes [tap] from the queue after the router has resolved it. No-op
  /// when the tap is not present.
  void consume(NotificationTap tap) {
    if (!state.contains(tap)) {
      return;
    }
    state = state.where((entry) => entry != tap).toList(growable: false);
  }

  /// Drops every queued tap.
  void clear() {
    if (state.isEmpty) return;
    state = const <NotificationTap>[];
  }
}
