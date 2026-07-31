import 'package:freezed_annotation/freezed_annotation.dart';

part 'feedback_form_value.freezed.dart';

@freezed
abstract class FeedbackAppMetadata with _$FeedbackAppMetadata {
  const factory FeedbackAppMetadata({
    required String appVersion,
    required String platform,
    required String locale,
  }) = _FeedbackAppMetadata;
}

@Freezed(copyWith: false)
class FeedbackDraft with _$FeedbackDraft {
  const FeedbackDraft({
    this.message = '',
    this.email,
    this.includeScreenshot = false,
  });

  const FeedbackDraft.empty() : message = '', email = null, includeScreenshot = false;

  @override
  final String message;

  @override
  final String? email;

  @override
  final bool includeScreenshot;

  bool get isEmpty => message.trim().isEmpty && email == null && !includeScreenshot;

  bool get hasMessage => message.trim().isNotEmpty;

  FeedbackDraft copyWith({
    String? message,
    String? email,
    bool? includeScreenshot,
    bool clearEmail = false,
  }) {
    return FeedbackDraft(
      message: message ?? this.message,
      email: clearEmail ? null : (email ?? this.email),
      includeScreenshot: includeScreenshot ?? this.includeScreenshot,
    );
  }
}

@freezed
abstract class FeedbackFormValue with _$FeedbackFormValue {
  const factory FeedbackFormValue({
    required String message,
    required bool includeScreenshot,
    required FeedbackAppMetadata appMetadata,
    String? email,
  }) = _FeedbackFormValue;
}
