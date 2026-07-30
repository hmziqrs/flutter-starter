import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A picked media artifact (today: a single image). Typed so the port surface
/// never leaks the plugin's `XFile` type. Immutable, structurally equal.
@immutable
final class PickedMedia {
  const PickedMedia({
    required this.path,
    required this.mimeType,
    required this.fromCamera,
  });

  /// Absolute path (or URI) the platform returned for the picked artifact.
  final String path;

  /// The MIME type the platform reported (e.g. `image/jpeg`). May be empty.
  final String mimeType;

  /// `true` when the artifact came from the camera, `false` from the library.
  final bool fromCamera;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PickedMedia &&
            path == other.path &&
            mimeType == other.mimeType &&
            fromCamera == other.fromCamera;
  }

  @override
  int get hashCode => Object.hash(path, mimeType, fromCamera);

  @override
  String toString() => 'PickedMedia(path: $path, mimeType: $mimeType, fromCamera: $fromCamera)';
}

/// Image / media selection port. Production adapter (`ImagePickerMediaPicker`)
/// talks to the OS via `image_picker`; the noop default returns `null`
/// (cancelled / unavailable) rather than faking a picked image.
// One-member abstract lint is a false positive for a multi-implementation port.
// ignore: one_member_abstracts
abstract interface class MediaPicker {
  /// Opens the platform image picker ([fromCamera] `true` = camera, `false` =
  /// photo library) and resolves to the picked [PickedMedia], or `null` when
  /// cancelled / unavailable. Never throws.
  Future<PickedMedia?> pickImage({bool fromCamera = false});
}

/// Thrown by [MediaPicker] adapters only for programmer errors (never for
/// plugin / cancellation outcomes, which resolve to `null`).
final class MediaPickerException implements Exception {
  const MediaPickerException({required this.operation});

  final String operation;

  @override
  String toString() => 'MediaPickerException: $operation failed';
}

/// Throws a [StateError] until the composition root overrides it with a
/// concrete adapter (`ImagePickerMediaPicker` on native, `NoopMediaPicker`
/// for web / integration tests).
final mediaPickerProvider = Provider<MediaPicker>(
  (ref) => throw StateError('MediaPicker must be overridden at the composition root.'),
);
