import 'package:freezed_annotation/freezed_annotation.dart';

part 'feedback_form_value.freezed.dart';

/// Read-only app environment attached to every feedback submission (no PII —
/// version / platform / locale only, never account identifiers). Built once
/// at the composition root from `AppBuildInfo` + `PlatformCapabilities` + the
/// active locale.
@freezed
abstract class FeedbackAppMetadata with _$FeedbackAppMetadata {
  const factory FeedbackAppMetadata({
    required String appVersion,
    required String platform,
    required String locale,
  }) = _FeedbackAppMetadata;

  /// Installed build version (for example `1.0.0+1`).
  /// Lowercase platform name (`ios`, `android`, `macos`, ...).
  /// Active BCP-47 locale tag (for example `en`, `ar`, `zh-Hans`).
}

/// The user-editable feedback draft. Owned by `FeedbackController`, persisted
/// so a half-written report survives backgrounding; cleared only on a
/// confirmed `accepted` result.
///
/// [email] is trimmed at the controller boundary before reaching this value.
/// [includeScreenshot] is the user's intent only — the Noop transport never
/// captures bytes, so the toggle is inert without a real backend.
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

  /// Optional reply-to address; `null` when the field was left blank.
  @override
  final String? email;

  /// User intent to attach a screenshot. Inert under the Noop transport.
  @override
  final bool includeScreenshot;

  /// `true` when there is nothing worth persisting.
  bool get isEmpty => message.trim().isEmpty && email == null && !includeScreenshot;

  /// `true` when the message has non-whitespace content; gates `submit()`.
  bool get hasMessage => message.trim().isNotEmpty;

  FeedbackDraft copyWith({
    String? message,
    String? email,
    bool? includeScreenshot,
    bool clearEmail = false,
  }) {
    return FeedbackDraft(
      message: message ?? this.message,
      // `email` is nullable, so a plain `??` cannot distinguish "keep" from
      // "clear"; the explicit [clearEmail] flag disambiguates.
      email: clearEmail ? null : (email ?? this.email),
      includeScreenshot: includeScreenshot ?? this.includeScreenshot,
    );
  }
}

/// The normalized value emitted by the feedback sheet after form validation,
/// built from `save()` + the live draft plus the `appMetadata` snapshot so
/// the transport payload (`FeedbackSubmission`) is derived in one step.
@freezed
abstract class FeedbackFormValue with _$FeedbackFormValue {
  const factory FeedbackFormValue({
    required String message,
    required bool includeScreenshot,
    required FeedbackAppMetadata appMetadata,
    String? email,
  }) = _FeedbackFormValue;

  /// Trimmed reply-to address, or `null` when the optional field was blank.
  /// Snapshot of the app environment at submit time.
}
