import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/notifications/notification_permission_status.dart';
import 'package:starter/features/notifications/notification_tap.dart';

// Doc cross-references to sibling-class names (NoopNotificationsRepository /
// FirebaseNotificationsRepository) are intentional `comment_references`.
// ignore_for_file: comment_references

/// Reasons a [NotificationsRepository] operation can fail. Surfaced to the UI
/// through [NotificationsException] -> i18n; never leaked as a raw token. The
/// honest no-backend default surfaces [notConnected] rather than fabricating a
/// granted permission or a registered token (C2: never fake success).
enum NotificationsFailureKind {
  /// No backend is configured or reachable. The default for
  /// [NoopNotificationsRepository] and for any transport failure on the real
  /// adapter's register/unregister path.
  notConnected,

  /// The OS denied authorization and the operation cannot proceed (e.g.
  /// registering a token while the user has denied notification permission).
  denied,

  /// A programmer or transport error not classified above.
  unknown,
}

/// Typed exception thrown by every [NotificationsRepository] operation.
/// Mirrors `SettingsStoreException` / `AuthException`: a typed reason the UI
/// maps to `notifications.*` i18n keys, with an optional underlying [cause]
/// that is never a raw token (the repository redacts before constructing
/// this).
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
/// drives behavior (C6). Mirrors `AnalyticsClientBackend` /
/// `CrashReporterBackend`.
sealed class NotificationsBackend {
  const NotificationsBackend();
}

/// No remote push provider is configured. Permission requests degrade to
/// [NotificationPermissionStatus.denied]; token registration surfaces
/// [NotificationsException.notConnected]; foreground / tap streams stay empty
/// — the honest no-backend default.
final class NoopNotificationsBackend extends NotificationsBackend {
  const NoopNotificationsBackend();
}

/// Push tokens are registered against a remote provider (FCM / APNs) and a
/// backend reachable at [registrationHost]. Messages and taps flow through the
/// native provider SDKs; only the token-registration / permission-revoked path
/// hits [registrationHost] over HTTP (C9: message delivery cannot be mocked by
/// a plain HTTP server).
final class RemoteNotificationsBackend extends NotificationsBackend {
  const RemoteNotificationsBackend({required this.registrationHost});

  final String registrationHost;
}

/// The push-notifications port.
///
/// Mirrors `SettingsStore` / `AuthRepository`: per-operation, `Future`-
/// returning, throwing a typed [NotificationsException]. **No production impl
/// is wired by default** (the no-backend rule, C2): the
/// [NoopNotificationsRepository] default reports
/// [NotificationPermissionStatus.denied], returns empty streams, and throws
/// [NotificationsException.notConnected] for the registration actions — never
/// faking a granted token. The optional real Firebase adapter — constructed in
/// `AppDependencies.production` only when the consumer provides Firebase
/// credentials — implements this against `firebase_messaging` for delivery and
/// the test-server token-registration contract (C9) for backend registration.
///
/// The port has a single reader (the notifications controller); it is **not** a
/// messaging bus (C4: do not multiply backends).
abstract interface class NotificationsRepository {
  /// Requests notification authorization from the OS. Returns the resulting
  /// [NotificationPermissionStatus]. Pass `provisional: true` to request
  /// iOS provisional authorization (silent delivery to the notification
  /// center). The Noop default returns [NotificationPermissionStatus.denied]
  /// without a prompt — the honest state without a backend.
  Future<NotificationPermissionStatus> requestPermission({required bool provisional});

  /// Mints and registers a platform push token with the backend, returning the
  /// token string (or `null` when authorization was never granted). Throws
  /// [NotificationsException.notConnected] when no backend is reachable (the
  /// honest no-backend default). The real adapter sends the token to the
  /// registration endpoint (`POST /v1/notifications/register-token`).
  Future<String?> registerToken();

  /// Server-side invalidation of [token]. The real adapter DELETEs the token
  /// from the registration endpoint. The Noop default throws
  /// [NotificationsException.notConnected] — best-effort at the call site.
  Future<void> unregisterToken(String token);

  /// Foreground message stream. The real adapter maps `firebase_messaging`'s
  /// `onMessage` stream to typed [NotificationMessage] values and posts a
  /// local notification through `flutter_local_notifications`. The Noop default
  /// publishes an empty stream (no messages arrive without a provider).
  Stream<NotificationMessage> get onMessage;

  /// Notification-opened (tap) stream, including the cold-start tap (a tap
  /// that launched the app). The real adapter folds
  /// `firebase_messaging`'s `getInitialMessage` future with its
  /// `onMessageOpenedApp` stream into one [NotificationTap] stream so the
  /// consumer observes taps in arrival order regardless of process state.
  /// The Noop default publishes an empty stream.
  Stream<NotificationTap> get onNotificationTap;
}

/// Handwritten Riverpod handle for the [NotificationsRepository] port.
///
/// Mirrors `settingsRepositoryProvider` / `analyticsClientProvider`: it throws
/// a [StateError] until the composition root overrides it. The no-backend
/// default (`NoopNotificationsRepository`) is constructed in
/// `AppDependencies.production` and wired in `lib/app/app.dart` as a peer of
/// the other port overrides. The optional real impl
/// (`FirebaseNotificationsRepository`) overrides this only when the consumer
/// wires Firebase credentials AND the platform is iOS or Android (the plugin
/// has no desktop/web support). No codegen.
final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => throw StateError(
    'NotificationsRepository must be overridden at the composition root.',
  ),
);

/// Read-only backend descriptor for the diagnostics page. Defaults to the
/// no-backend [NoopNotificationsBackend]; overridden at the [ProviderScope]
/// when a remote push provider is configured. Mirrors
/// `analyticsClientBackendProvider`.
final notificationsBackendProvider = Provider<NotificationsBackend>(
  (ref) => const NoopNotificationsBackend(),
);
