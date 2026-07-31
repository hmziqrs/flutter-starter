// Doc cross-references to sibling-class names in the feature package are
// intentional `comment_references`.
// ignore_for_file: comment_references

import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_tap.freezed.dart';

/// A foreground push payload delivered while the app is open. Foreground
/// rendering is delegated to `flutter_local_notifications` by the optional
/// real adapter; the Noop default publishes nothing on
/// [NotificationsRepository.onMessage].
@freezed
abstract class NotificationMessage with _$NotificationMessage {
  const factory NotificationMessage({
    String? title,
    String? body,
    @Default(<String, String>{}) Map<String, String> data,
  }) = _NotificationMessage;

  /// Optional human-readable title. `null` for data-only messages.
  /// Optional human-readable body. `null` for data-only messages.
  /// String-typed data payload; plugin values are coerced to strings so the
  /// feature surface never leaks `dynamic`.
}

/// A notification-opened (tap) event consumed by the router. The optional
/// real adapter folds `firebase_messaging`'s `getInitialMessage` (cold-start
/// tap) with its `onMessageOpenedApp` stream into one arrival-ordered stream.
/// The router resolves [targetRoute] to an existing named route via
/// `context.pushNamed`; [params] carries the typed route arguments. The Noop
/// default publishes an empty stream.
@freezed
abstract class NotificationTap with _$NotificationTap {
  const factory NotificationTap({
    required String targetRoute,
    @Default(<String, String>{}) Map<String, String> params,
  }) = _NotificationTap;

  /// Existing named route the tap should resolve to. The router is the sole
  /// resolver — `NotificationTap` never carries a raw URI.
  /// Typed route params, coerced to strings so the router surface never
  /// leaks `dynamic`.
}
