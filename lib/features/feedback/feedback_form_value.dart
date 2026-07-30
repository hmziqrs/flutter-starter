import 'package:flutter/foundation.dart';

/// Read-only app environment attached to every feedback submission (no PII —
/// version / platform / locale only, never account identifiers). Built once
/// at the composition root from `AppBuildInfo` + `PlatformCapabilities` + the
/// active locale.
@immutable
final class FeedbackAppMetadata {
  const FeedbackAppMetadata({
    required this.appVersion,
    required this.platform,
    required this.locale,
  });

  /// Installed build version (for example `1.0.0+1`).
  final String appVersion;

  /// Lowercase platform name (`ios`, `android`, `macos`, ...).
  final String platform;

  /// Active BCP-47 locale tag (for example `en`, `ar`, `zh-Hans`).
  final String locale;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FeedbackAppMetadata &&
            appVersion == other.appVersion &&
            platform == other.platform &&
            locale == other.locale;
  }

  @override
  int get hashCode => Object.hash(appVersion, platform, locale);
}

/// The user-editable feedback draft. Owned by `FeedbackController`, persisted
/// so a half-written report survives backgrounding; cleared only on a
/// confirmed `accepted` result.
///
/// [email] is trimmed at the controller boundary before reaching this value.
/// [includeScreenshot] is the user's intent only — the Noop transport never
/// captures bytes, so the toggle is inert without a real backend.
@immutable
final class FeedbackDraft {
  const FeedbackDraft({
    this.message = '',
    this.email,
    this.includeScreenshot = false,
  });

  const FeedbackDraft.empty() : message = '', email = null, includeScreenshot = false;

  final String message;

  /// Optional reply-to address; `null` when the field was left blank.
  final String? email;

  /// User intent to attach a screenshot. Inert under the Noop transport.
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

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FeedbackDraft &&
            message == other.message &&
            email == other.email &&
            includeScreenshot == other.includeScreenshot;
  }

  @override
  int get hashCode => Object.hash(message, email, includeScreenshot);
}

/// The normalized value emitted by the feedback sheet after form validation,
/// built from `save()` + the live draft plus the `appMetadata` snapshot so
/// the transport payload (`FeedbackSubmission`) is derived in one step.
@immutable
final class FeedbackFormValue {
  const FeedbackFormValue({
    required this.message,
    required this.includeScreenshot,
    required this.appMetadata,
    this.email,
  });

  final String message;

  /// Trimmed reply-to address, or `null` when the optional field was blank.
  final String? email;

  final bool includeScreenshot;

  /// Snapshot of the app environment at submit time.
  final FeedbackAppMetadata appMetadata;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FeedbackFormValue &&
            message == other.message &&
            email == other.email &&
            includeScreenshot == other.includeScreenshot &&
            appMetadata == other.appMetadata;
  }

  @override
  int get hashCode => Object.hash(message, email, includeScreenshot, appMetadata);
}
