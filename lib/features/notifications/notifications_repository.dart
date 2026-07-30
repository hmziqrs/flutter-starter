import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/notifications/notification_permission_status.dart';
import 'package:starter/features/notifications/notification_tap.dart';

// Doc cross-references to sibling-class names (NoopNotificationsRepository /
// FirebaseNotificationsRepository) are intentional `comment_references`.
// ignore_for_file: comment_references

/// Reasons a [NotificationsRepository] operation can fail. Surfaced to the UI
/// through [NotificationsException] -> i18n; never leaked as a raw token.
enum NotificationsFailureKind {
  /// No backend is configured or reachable.
  notConnected,

  /// The OS denied authorization and the operation cannot proceed.
  denied,

  /// A programmer or transport error not classified above.
  unknown,
}

/// Typed exception thrown by every [NotificationsRepository] operation. A
/// typed reason the UI maps to `notifications.*` i18n keys, with an optional
/// underlying [cause] that is never a raw token.
final class NotificationsException implements Exception {
  const NotificationsException.notConnected()
    : kind = NotificationsFailureKind.notConnected,
      cause = null;

  const NotificationsException.denied([this.cause]) : kind = NotificationsFailureKind.denied;

  const NotificationsException.unknown([this.cause]) : kind = NotificationsFailureKind.unknown;

  final NotificationsFailureKind kind;

  /// The underlying error, if any. Forwarded to crash reporting already
  /// redacted; never a raw token.
  final Object? cause;

  @override
  String toString() => 'NotificationsException(${kind.name})';
}

/// Read-only description of where a [NotificationsRepository] delivers
/// tokens / messages. Surfaced on the development `DiagnosticsPage`; never
/// drives behavior.
sealed class NotificationsBackend {
  const NotificationsBackend();
}

/// No remote push provider is configured. Permission requests degrade to
/// [NotificationPermissionStatus.denied]; token registration surfaces
/// [NotificationsException.notConnected]; foreground / tap streams stay empty.
final class NoopNotificationsBackend extends NotificationsBackend {
  const NoopNotificationsBackend();
}

/// Push tokens are registered against a remote provider (FCM / APNs) and a
/// backend reachable at [registrationHost]. Messages and taps flow through
/// the native provider SDKs; only the token-registration / permission-revoked
/// path hits [registrationHost] over HTTP.
final class RemoteNotificationsBackend extends NotificationsBackend {
  const RemoteNotificationsBackend({required this.registrationHost});

  final String registrationHost;
}

/// The push-notifications port: per-operation, `Future`-returning, throwing a
/// typed [NotificationsException]. No production impl is wired by default:
/// the [NoopNotificationsRepository] default reports
/// [NotificationPermissionStatus.denied], returns empty streams, and throws
/// [NotificationsException.notConnected] for the registration actions. The
/// optional real Firebase adapter implements this against
/// `firebase_messaging` for delivery and the test-server token-registration
/// contract for backend registration.
///
/// The port has a single reader (the notifications controller); it is not a
/// messaging bus.
abstract interface class NotificationsRepository {
  /// Requests notification authorization from the OS. Pass `provisional:
  /// true` to request iOS provisional authorization (silent delivery to the
  /// notification center). The Noop default returns
  /// [NotificationPermissionStatus.denied] without a prompt.
  Future<NotificationPermissionStatus> requestPermission({required bool provisional});

  /// Mints and registers a platform push token with the backend, returning
  /// the token string (or `null` when authorization was never granted).
  /// Throws [NotificationsException.notConnected] when no backend is
  /// reachable. The real adapter sends the token to
  /// `POST /v1/notifications/register-token`.
  Future<String?> registerToken();

  /// Server-side invalidation of [token]. The Noop default throws
  /// [NotificationsException.notConnected] — best-effort at the call site.
  Future<void> unregisterToken(String token);

  /// Foreground message stream. The real adapter maps `firebase_messaging`'s
  /// `onMessage` stream to typed [NotificationMessage] values. The Noop
  /// default publishes an empty stream.
  Stream<NotificationMessage> get onMessage;

  /// Notification-opened (tap) stream, including the cold-start tap. The
  /// real adapter folds `firebase_messaging`'s `getInitialMessage` future
  /// with its `onMessageOpenedApp` stream into one arrival-ordered
  /// [NotificationTap] stream. The Noop default publishes an empty stream.
  Stream<NotificationTap> get onNotificationTap;
}

/// Handwritten Riverpod handle for the [NotificationsRepository] port; throws
/// a [StateError] until the composition root overrides it. The no-backend
/// default (`NoopNotificationsRepository`) is constructed in
/// `AppDependencies.production`. The optional real impl
/// (`FirebaseNotificationsRepository`) overrides this only when the consumer
/// wires Firebase credentials AND the platform is iOS or Android.
final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => throw StateError(
    'NotificationsRepository must be overridden at the composition root.',
  ),
);

/// Read-only backend descriptor for the diagnostics page. Defaults to the
/// no-backend [NoopNotificationsBackend]; overridden at the [ProviderScope]
/// when a remote push provider is configured.
final notificationsBackendProvider = Provider<NotificationsBackend>(
  (ref) => const NoopNotificationsBackend(),
);
