import 'package:starter/infrastructure/media/media_picker.dart';

/// Deterministic "no media backend" [MediaPicker], selected for web,
/// unsupported platforms, and test/golden runs. Resolves every pick to `null`
/// rather than faking an image; the avatar flow surfaces
/// `profile.update.avatarUnavailable` as a result.
class NoopMediaPicker implements MediaPicker {
  const NoopMediaPicker();

  @override
  Future<PickedMedia?> pickImage({bool fromCamera = false}) async => null;
}
