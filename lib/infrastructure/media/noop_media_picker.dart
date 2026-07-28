import 'package:starter/infrastructure/media/media_picker.dart';

/// Deterministic, honest "no media backend" [MediaPicker].
///
/// The composition root selects this adapter for web, unsupported platforms,
/// and integration-test / golden runs (keyed off `PlatformCapabilities`, never a
/// global) so the starter stays green and goldens stay stable without ever
/// triggering the platform picker. Per the no-backend / honest-feedback contracts
/// (C2 / C13) it resolves every pick to `null` (the honest "cancelled /
/// unavailable" outcome) and **never fakes a picked image** — the avatar flow
/// surfaces `profile.update.avatarUnavailable` to the user as a result.
class NoopMediaPicker implements MediaPicker {
  const NoopMediaPicker();

  @override
  Future<PickedMedia?> pickImage({bool fromCamera = false}) async {
    // Honest: no backend, no image. Never fake success.
    return null;
  }
}
