import 'package:starter/infrastructure/media/media_picker.dart';

class NoopMediaPicker implements MediaPicker {
  const NoopMediaPicker();

  @override
  Future<PickedMedia?> pickImage({bool fromCamera = false}) async => null;
}
