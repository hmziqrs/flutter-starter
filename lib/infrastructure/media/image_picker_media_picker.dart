import 'package:image_picker/image_picker.dart';
import 'package:starter/infrastructure/logging/app_logger.dart';
import 'package:starter/infrastructure/media/media_picker.dart';

class ImagePickerMediaPicker implements MediaPicker {
  ImagePickerMediaPicker({ImagePicker? picker, AppLogger? logger})
    : _picker = picker ?? ImagePicker(),
      _logger = logger ?? AppLogger.bootstrap();

  final ImagePicker _picker;

  final AppLogger _logger;

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
    } on Object catch (error, stackTrace) {
      _logger.warning(
        'media.pick_image_failed',
        error: error,
        stackTrace: stackTrace,
        context: {'fromCamera': fromCamera},
      );
      return null;
    }
  }
}
