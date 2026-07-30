import 'package:starter/features/notifications/notifications_repository.dart';

/// Token-registration port for the notifications backend.
///
/// The test-server push contract covers only the token-registration /
/// permission path: `POST /v1/notifications/register-token`,
/// `DELETE /v1/notifications/register-token/{token}`,
/// `POST /v1/notifications/permission-revoked`. Message delivery (FCM / APNs)
/// can't be mocked by a plain HTTP server and is handled by
/// `firebase_messaging` directly inside `FirebaseNotificationsRepository`.
abstract interface class NotificationsRegistration {
  /// Registers [token] with the backend, scoped to [platform] / [deviceId].
  /// Idempotent: the server stores each `(deviceId, token)` once. Throws
  /// [NotificationsException.notConnected] when the backend is unreachable.
  Future<void> registerToken({
    required String token,
    required String platform,
    required String deviceId,
  });

  /// Server-side invalidation of [token]. Idempotent.
  Future<void> unregisterToken(String token);

  /// Reports that the user revoked notification permission for [deviceId], so
  /// the backend stops sending to a device that will silently drop every push.
  Future<void> reportPermissionRevoked({required String deviceId});
}
