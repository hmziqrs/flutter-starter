import 'dart:async';

// Doc cross-references to sibling-class names in the feature package are
// intentional `comment_references`.
// ignore_for_file: comment_references

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/notifications/notification_permission_status.dart';
import 'package:starter/features/notifications/notification_tap.dart';
import 'package:starter/features/notifications/notifications_repository.dart';

/// Coarse lifecycle of the token-registration state machine. Surfaced on the
/// rationale sheet and the diagnostics page so the UI can reflect
/// "registering" / "registered" / "unavailable" without leaking the underlying
/// exception.
enum NotificationsRegistrationState {
  /// No registration attempt has been made yet (the default).
  idle,

  /// A `registerToken` call is in flight.
  registering,

  /// A token was successfully registered with the backend.
  registered,

  /// The registration path surfaced [NotificationsException.notConnected] —
  /// the honest no-backend default lands here rather than faking success.
  unavailable,

  /// A non-notConnected failure (denied / unknown). The rationale sheet
  /// surfaces `notifications.disabled` or the generic error copy.
  failed,
}

/// Immutable snapshot of the notifications controller state. Mirrors the
/// `SettingsState` / `BiometricLockState` shape: value-equal so it flows
/// through Riverpod unchanged, with a `[NotificationsRegistrationState]`
/// discriminator and the latest typed permission / token fields.
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
  /// the [LogRedactor] scrubs token-shaped strings before any structured
  /// context reaches the log.
  final String? token;

  final NotificationsRegistrationState registration;

  /// True when the registration path is honest-unavailable — surfaced by the
  /// rationale sheet as `notifications.disabled` / `common.notConnected`.
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

/// Cold-start seed for the persisted permission status. Pre-loaded in
/// `AppDependencies.production` (a single `SettingsStore` read of
/// [persistedPermissionKey]) and overridden at the `ProviderScope` — mirrors
/// `initialAnalyticsOptInProvider`. Pre-loading lets the controller resolve
/// synchronously to the persisted value on the first frame.
final initialNotificationPermissionProvider = Provider<NotificationPermissionStatus>(
  (ref) => NotificationPermissionStatus.notRequested,
);

/// Cold-start seed for the persisted registered token, if any. Pre-loaded
/// alongside the permission status so the rationale sheet can render the
/// "registered" state without waiting on a backend round-trip.
final initialNotificationTokenProvider = Provider<String?>((ref) => null);

/// Handwritten Riverpod `Notifier<NotificationsState>` for the notifications
/// permission + token-registration state machine.
///
/// Mirrors `SettingsController` / `AnalyticsOptInController`: optimistic state
/// transitions, typed exceptions caught and surfaced as
/// [NotificationsRegistrationState.unavailable] (the honest no-backend
/// landing) rather than faking success, no codegen. Permission status and the
/// last-registered token are persisted under the single
/// [persistedPermissionKey] / [persistedTokenKey] `SettingsStore` keys so a
/// returning user sees their previous authorization on the first frame.
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

  /// Requests notification authorization from the OS via the repository. The
  /// resulting [NotificationPermissionStatus] is persisted (mirrors
  /// `SettingsController._replace`) and reflected in [state.permission]. A
  /// failure rolls back to the previous value and lands the registration state
  /// in [NotificationsRegistrationState.failed].
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

  /// Requests permission if needed, then registers the token. The honest
  /// no-backend default throws [NotificationsException.notConnected] inside
  /// `registerToken`; the controller catches it and lands the state in
  /// [NotificationsRegistrationState.unavailable] so the rationale sheet can
  /// surface `notifications.disabled` / `common.notConnected` (guardrail 13).
  /// Never fakes a registered token.
  ///
  /// Permission gating is delegated to the repository: the in-memory fake and
  /// the Noop both throw a typed exception from `registerToken` when
  /// authorization is missing (`denied`) or no backend is reachable
  /// (`notConnected`). The exception kind — not the controller's local view of
  /// the permission status — drives the final landing state, so the Noop
  /// (whose `requestPermission` honestly returns `denied`) still surfaces
  /// `unavailable` because its `registerToken` throws `notConnected`.
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
  /// regardless of whether the backend call succeeds — a network failure
  /// during opt-out must not strand the user in a "registered" state. The
  /// no-backend default throws [NotificationsException.notConnected] which is
  /// swallowed here; the local state still flips to idle.
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
      // Best-effort: local state already cleared. The next register() will
      // mint a fresh token if a backend becomes reachable.
    }
  }
}

/// `SettingsStore` keys persisting the notifications state across launches.
/// The token is a *delivery address*, not a credential, so `SettingsStore`
/// (plaintext) is appropriate — see the feature spec Risks section. If a
/// consumer later treats the device identity as sensitive, route it through
/// the shared `SecureStore` port instead (do not add a second secrets adapter).
const String persistedPermissionKey = 'notifications.permission';
const String persistedTokenKey = 'notifications.token';

/// Handwritten Riverpod `Notifier<List<NotificationTap>>` that buffers
/// notification taps (foreground + cold-start) in arrival order until the
/// router drains them.
///
/// Subscribes to [NotificationsRepository.onNotificationTap] inside [build]
/// so the subscription is alive the moment the provider is first read — and
/// the cold-start tap is therefore captured into the queue before
/// `_AppViewState` mounts its `ref.listen` drain (the spec's plugin-init
/// ordering guarantee: the messaging plugin is initialized in
/// `createApplication` before the router is built, and this provider is read
/// in `_AppViewState.initState`).
final notificationTapQueueProvider = NotifierProvider<NotificationTapQueue, List<NotificationTap>>(
  NotificationTapQueue.new,
);

final class NotificationTapQueue extends Notifier<List<NotificationTap>> {
  StreamSubscription<NotificationTap>? _subscription;

  @override
  List<NotificationTap> build() {
    final repository = ref.watch(notificationsRepositoryProvider);
    // Subscribe immediately so a foreground tap arriving between queue creation
    // and the first read is still captured. unawaited documents the intent;
    // the stream stays open for the lifetime of this provider.
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

  /// Removes [tap] from the queue (called by the router after the tap has been
  /// routed to its destination). No-op when the tap is not present.
  void consume(NotificationTap tap) {
    if (!state.contains(tap)) {
      return;
    }
    state = state.where((entry) => entry != tap).toList(growable: false);
  }

  /// Drops every queued tap. Used by tests and by an explicit "clear" affordance
  /// if the router cannot resolve a tap (e.g. a deep link to an unknown route).
  void clear() {
    if (state.isEmpty) return;
    state = const <NotificationTap>[];
  }
}
