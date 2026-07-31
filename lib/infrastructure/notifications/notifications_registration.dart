abstract interface class NotificationsRegistration {
  /// Idempotent: the server stores each `(deviceId, token)` once.
  Future<void> registerToken({
    required String token,
    required String platform,
    required String deviceId,
  });

  Future<void> unregisterToken(String token);

  Future<void> reportPermissionRevoked({required String deviceId});
}
