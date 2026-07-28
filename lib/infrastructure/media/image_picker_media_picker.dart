import 'package:image_picker/image_picker.dart';
import 'package:starter/infrastructure/media/media_picker.dart';

/// Production [MediaPicker] backed by the `image_picker` OS plugin.
///
/// Constructed in `AppDependencies.production` (the composition root) only on
/// supported platforms; web / integration-test runs use `NoopMediaPicker`
/// instead, selected from `PlatformCapabilities`. The plugin is never referenced
/// outside this adapter — every consumer reads the typed [PickedMedia] / `null`
/// surface (C2: no widget calls a plugin directly).
///
/// Degrades honestly inside `try/on Object` (C13: never fake success): a
/// cancelled pick returns `null`, and a plugin error also returns `null`
/// (the honest "unavailable" outcome) rather than surfacing an error or
/// fabricating an image.
class ImagePickerMediaPicker implements MediaPicker {
  ImagePickerMediaPicker({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<PickedMedia?> pickImage({bool fromCamera = false}) async {
    try {
      final source = fromCamera ? ImageSource.camera : ImageSource.gallery;
      final result = await _picker.pickImage(source: source, imageQuality: 90);
      if (result == null) {
        // User cancelled — honest null, never a fabricated image.
        return null;
      }
      return PickedMedia(
        path: result.path,
        // `XFile.mimeType` is nullable in some plugin versions; treat a null
        // report as an empty string so the value object stays non-nullable.
        mimeType: result.mimeType ?? '',
        fromCamera: fromCamera,
      );
    } on Object {
      // Plugin error / missing platform binding — honest unavailable.
      return null;
    }
  }
}
