import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_tap.freezed.dart';

@freezed
abstract class NotificationMessage with _$NotificationMessage {
  const factory NotificationMessage({
    String? title,
    String? body,
    @Default(<String, String>{}) Map<String, String> data,
  }) = _NotificationMessage;
}

@freezed
abstract class NotificationTap with _$NotificationTap {
  const factory NotificationTap({
    required String targetRoute,
    @Default(<String, String>{}) Map<String, String> params,
  }) = _NotificationTap;
}
