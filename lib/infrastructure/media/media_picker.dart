import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
final class PickedMedia {
  const PickedMedia({
    required this.path,
    required this.mimeType,
    required this.fromCamera,
  });

  final String path;

  final String mimeType;

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

// One-member abstract lint is a false positive for a multi-implementation port.
// ignore: one_member_abstracts
abstract interface class MediaPicker {
  Future<PickedMedia?> pickImage({bool fromCamera = false});
}

final class MediaPickerException implements Exception {
  const MediaPickerException({required this.operation});

  final String operation;

  @override
  String toString() => 'MediaPickerException: $operation failed';
}

final mediaPickerProvider = Provider<MediaPicker>(
  (ref) => throw StateError('MediaPicker must be overridden at the composition root.'),
);
