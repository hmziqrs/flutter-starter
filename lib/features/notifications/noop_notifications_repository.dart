import 'package:starter/features/notifications/notification_permission_status.dart';
import 'package:starter/features/notifications/notification_tap.dart';
import 'package:starter/features/notifications/notifications_repository.dart';

/// Production default [NotificationsRepository].
///
/// Runs green with zero backend: it reports
/// [NotificationPermissionStatus.denied] for permission requests, publishes
/// empty foreground / tap streams, and throws
/// [NotificationsException.notConnected] for the token-registration actions.
/// It **never fakes a granted token or a delivered message** (C2 / guardrail
/// 13): the controller catches [NotificationsException.notConnected] and
/// surfaces `notifications.disabled` / `common.notConnected` honestly so the
/// rationale copy matches what a real device shows when no provider is wired.
///
/// Constructed in `AppDependencies.production` and overridden at the
/// `ProviderScope` in `lib/app/app.dart`. The optional real Firebase adapter
/// overrides the provider only when the consumer wires Firebase credentials
/// (never by default). Selected for desktop / web via `PlatformCapabilities`
/// (`firebase_messaging` has no desktop / web support) — the platform decision
/// happens at the composition root, not here.
final class NoopNotificationsRepository implements NotificationsRepository {
  const NoopNotificationsRepository();

  @override
  Future<NotificationPermissionStatus> requestPermission({
    required bool provisional,
  }) async {
    // Honest state without a backend: notifications are never authorized when
    // no provider is wired. The rationale sheet surfaces the disabled copy.
    return NotificationPermissionStatus.denied;
  }

  @override
  Future<String?> registerToken() async {
    // No backend: surface notConnected so the controller can show
    // `notifications.disabled` honestly. Returning `null` silently would read
    // as "no token yet" and obscure that no provider is configured.
    throw const NotificationsException.notConnected();
  }

  @override
  Future<void> unregisterToken(String token) async {
    // Best-effort action with no backend — surface notConnected. The caller
    // treats registration-action failures as non-fatal (logout / opt-out paths
    // continue regardless), but the contract never claims success.
    throw const NotificationsException.notConnected();
  }

  @override
  Stream<NotificationMessage> get onMessage => const Stream<NotificationMessage>.empty();

  @override
  Stream<NotificationTap> get onNotificationTap => const Stream<NotificationTap>.empty();
}
