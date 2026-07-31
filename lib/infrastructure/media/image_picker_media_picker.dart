import 'package:image_picker/image_picker.dart';
import 'package:starter/infrastructure/media/media_picker.dart';

class ImagePickerMediaPicker implements MediaPicker {
  ImagePickerMediaPicker({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<PickedMedia?> pickImage({bool fromCamera = false}) async {
    try {
      final source = fromCamera ? ImageSource.camera : ImageSource.gallery;
      final result = await _picker.pickImage(source: source, imageQuality: 90);
      if (result == null) {
        return null;
      }
      return PickedMedia(
        path: result.path,
        mimeType: result.mimeType ?? '',
        fromCamera: fromCamera,
      );
    } on Object {
      return null;
    }
  }
}
