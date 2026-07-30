import 'dart:async';

// Private-field constructor with public-named parameters and intentional
// doc cross-references — same shape as the sibling notifications adapters.
// ignore_for_file: prefer_initializing_formals, comment_references

import 'package:starter/features/notifications/notification_permission_status.dart';
import 'package:starter/features/notifications/notification_tap.dart';
import 'package:starter/features/notifications/notifications_repository.dart';

/// Deterministic in-memory [NotificationsRepository] for widget / controller
/// tests and the dev-gallery fixtures: controllable permission state, a fake
/// message stream, and a fake tap stream — no plugin, no Firebase, no
/// persistence. `requestPermission` honors the
/// [NotificationPermissionStatus.notRequested] -> granted transition; seeded
/// permission values short-circuit the prompt. `registerToken` /
/// `unregisterToken` succeed against the seeded token.
///
/// `permission` is a public mutable field (test knob) so a fixture can pin a
/// state without driving the prompt.
///
/// Test / fixture only. Never constructed in `AppDependencies.production`
/// (the [NoopNotificationsRepository] is the production default).
final class InMemoryNotificationsRepository implements NotificationsRepository {
  InMemoryNotificationsRepository({
    NotificationPermissionStatus permission = NotificationPermissionStatus.notRequested,
    String? token,
  }) : permission = permission,
       token = token;

  /// Current permission status. Mutable test knob: a fixture assigns
  /// directly (e.g. `..permission = NotificationPermissionStatus.denied`).
  NotificationPermissionStatus permission;

  /// Current registered token (or `null`). Mutable so a test can seed an
  /// already-registered state.
  String? token;

  final StreamController<NotificationMessage> _messages =
      StreamController<NotificationMessage>.broadcast();
  final StreamController<NotificationTap> _taps = StreamController<NotificationTap>.broadcast();

  /// Test knob: injects a foreground message into the [onMessage] stream.
  void deliverMessage(NotificationMessage message) {
    _messages.add(message);
  }

  /// Test knob: injects a notification tap into the [onNotificationTap]
  /// stream.
  void deliverTap(NotificationTap tap) {
    _taps.add(tap);
  }

  @override
  Future<NotificationPermissionStatus> requestPermission({
    required bool provisional,
  }) async {
    if (permission == NotificationPermissionStatus.notRequested) {
      permission = provisional
          ? NotificationPermissionStatus.provisional
          : NotificationPermissionStatus.granted;
    }
    return permission;
  }

  @override
  Future<String?> registerToken() async {
    if (!permission.canDeliver) {
      throw const NotificationsException.denied();
    }
    return token ??= 'in-memory-token-${DateTime.now().microsecondsSinceEpoch}';
  }

  @override
  Future<void> unregisterToken(String token) async {
    if (this.token == token) {
      this.token = null;
    }
  }

  @override
  Stream<NotificationMessage> get onMessage => _messages.stream;

  @override
  Stream<NotificationTap> get onNotificationTap => _taps.stream;

  /// Releases the broadcast controllers. Call from `tearDown`.
  void dispose() {
    unawaited(_messages.close());
    unawaited(_taps.close());
  }
}
