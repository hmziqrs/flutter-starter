import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A picked media artifact (today: a single image). Typed so the port surface
/// never leaks a plugin type (`XFile`) — every consumer reads [path] +
/// [mimeType]. Immutable value object with structural equality.
///
/// Generalizes beyond the avatar: future share-result and feedback-screenshot
/// flows reuse the same value. The [fromCamera] flag records the source so the
/// caller can branch on camera vs library without re-reading the plugin.
@immutable
final class PickedMedia {
  const PickedMedia({
    required this.path,
    required this.mimeType,
    required this.fromCamera,
  });

  /// Absolute path (or URI) the platform returned for the picked artifact.
  final String path;

  /// The MIME type the platform reported (e.g. `image/jpeg`). May be empty when
  /// the platform could not infer one — callers must tolerate that.
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

/// Image / media selection port.
///
/// Mirrors the `SettingsStore` / `PermissionService` port shape: a
/// single-purpose, `Future`-returning surface owned under `lib/infrastructure/`,
/// with a typed exception ([MediaPickerException]) and `try/on Object`
/// degradation inside the adapters. There is **no** `clearAll`-style bulk call.
///
/// Backend-free per the no-backend contract (C2 / C13): the production adapter
/// (`ImagePickerMediaPicker`) talks to the OS via `image_picker`; the
/// deterministic default (`NoopMediaPicker`) returns `null` honestly
/// (cancelled / unavailable) and **never fakes a picked image** — surfacing the
/// `profile.update.avatarUnavailable` message to the user. No widget calls the
/// plugin directly.
// A single dispatch method is the intended shape for this port (the device
// adapter wraps `image_picker`). The one-member abstract lint is a false
// positive for a multi-implementation port.
// ignore: one_member_abstracts
abstract interface class MediaPicker {
  /// Opens the platform image picker for [fromCamera] (`true` = camera,
  /// `false` = photo library) and resolves to the picked [PickedMedia], or
  /// `null` when the user cancelled / no artifact is available.
  ///
  /// Adapters never throw for plugin failures: a failing pick resolves to
  /// `null` (the honest "unavailable" outcome) rather than surfacing an error
  /// to the UI.
  Future<PickedMedia?> pickImage({bool fromCamera = false});
}

/// Thrown by [MediaPicker] adapters only for programmer errors (never for
/// plugin / cancellation outcomes, which resolve to `null` honestly).
final class MediaPickerException implements Exception {
  const MediaPickerException({required this.operation});

  final String operation;

  @override
  String toString() => 'MediaPickerException: $operation failed';
}

/// Handwritten Riverpod handle for the [MediaPicker] port.
///
/// Mirrors `permissionServiceProvider` / `hapticServiceProvider`: it throws a
/// [StateError] until the composition root overrides it with a concrete
/// adapter. The composition root selects `ImagePickerMediaPicker` on supported
/// native platforms or the honest `NoopMediaPicker` for web / integration-test
/// runs (selected from `PlatformCapabilities` in `AppDependencies.production`,
/// never via a global), and wires the override in `lib/app/app.dart` as a peer
/// of the other port overrides.
final mediaPickerProvider = Provider<MediaPicker>(
  (ref) => throw StateError('MediaPicker must be overridden at the composition root.'),
);
