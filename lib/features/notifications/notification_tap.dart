// Doc cross-references to sibling-class names in the feature package are
// intentional `comment_references`.
// ignore_for_file: comment_references

import 'package:flutter/foundation.dart';

/// A foreground push payload delivered while the app is open. Foreground
/// rendering is delegated to `flutter_local_notifications` by the optional
/// real adapter; the Noop default publishes nothing on
/// [NotificationsRepository.onMessage].
@immutable
final class NotificationMessage {
  const NotificationMessage({this.title, this.body, this.data = const <String, String>{}});

  /// Optional human-readable title. `null` for data-only messages.
  final String? title;

  /// Optional human-readable body. `null` for data-only messages.
  final String? body;

  /// String-typed data payload; plugin values are coerced to strings so the
  /// feature surface never leaks `dynamic`.
  final Map<String, String> data;

  NotificationMessage copyWith({String? title, String? body, Map<String, String>? data}) {
    return NotificationMessage(
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationMessage &&
        other.title == title &&
        other.body == body &&
        _mapEquals(other.data, data);
  }

  @override
  int get hashCode => Object.hash(title, body, _hashMap(data));

  static bool _mapEquals(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}

/// Hashes a string-keyed map by its (key, value) pairs so two equal maps
/// produce equal hashes (`MapEntry.hashCode` is identity-based and would
/// otherwise diverge for equal maps).
int _hashMap(Map<String, String> map) {
  var hash = 0;
  for (final entry in map.entries) {
    hash ^= Object.hash(entry.key, entry.value);
  }
  return hash;
}

/// A notification-opened (tap) event consumed by the router. The optional
/// real adapter folds `firebase_messaging`'s `getInitialMessage` (cold-start
/// tap) with its `onMessageOpenedApp` stream into one arrival-ordered stream.
/// The router resolves [targetRoute] to an existing named route via
/// `context.pushNamed`; [params] carries the typed route arguments. The Noop
/// default publishes an empty stream.
@immutable
final class NotificationTap {
  const NotificationTap({required this.targetRoute, this.params = const <String, String>{}});

  /// Existing named route the tap should resolve to. The router is the sole
  /// resolver — `NotificationTap` never carries a raw URI.
  final String targetRoute;

  /// Typed route params, coerced to strings so the router surface never
  /// leaks `dynamic`.
  final Map<String, String> params;

  NotificationTap copyWith({String? targetRoute, Map<String, String>? params}) {
    return NotificationTap(
      targetRoute: targetRoute ?? this.targetRoute,
      params: params ?? this.params,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationTap &&
        other.targetRoute == targetRoute &&
        _mapEquals(other.params, params);
  }

  @override
  int get hashCode => Object.hash(targetRoute, _hashMap(params));

  static bool _mapEquals(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}
