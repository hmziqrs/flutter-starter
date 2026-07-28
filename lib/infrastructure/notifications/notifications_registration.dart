// Doc cross-references to sibling-class names (NotificationsException etc.)
// imported only via the feature package are intentional `comment_references`.
// ignore_for_file: comment_references

import 'package:starter/features/notifications/notifications_repository.dart';

/// Token-registration port for the notifications backend.
///
/// Per [C9](../../../plans/feature_roadmap/contracts.md#c9--test-server-route-conventions),
/// the test-server push contract covers **only the token-registration /
/// permission path**: `POST /v1/notifications/register-token`,
/// `DELETE /v1/notifications/register-token/{token}`,
/// `POST /v1/notifications/permission-revoked`. Message delivery (FCM / APNs)
/// cannot be mocked by a plain HTTP server and is handled by
/// `firebase_messaging` directly inside `FirebaseNotificationsRepository`.
///
/// This indirection keeps the HTTP path testable in isolation: integration
/// tests start the test server on a random port and construct an
/// [HttpNotificationsRegistrationClient] pointed at it, exercising the real
/// contract surface without a real push provider.
abstract interface class NotificationsRegistration {
  /// Registers [token] with the backend, scoped to [platform] / [deviceId].
  /// Idempotent: the server stores each `(deviceId, token)` once. Throws
  /// [NotificationsException.notConnected] when the backend is unreachable.
  Future<void> registerToken({
    required String token,
    required String platform,
    required String deviceId,
  });

  /// Server-side invalidation of [token]. Idempotent. Throws
  /// [NotificationsException.notConnected] when the backend is unreachable.
  Future<void> unregisterToken(String token);

  /// Reports that the user revoked notification permission for [deviceId].
  /// Allows the backend to stop sending to a device that will silently drop
  /// every push. Throws [NotificationsException.notConnected] when the backend
  /// is unreachable.
  Future<void> reportPermissionRevoked({required String deviceId});
}
