import 'package:flutter/foundation.dart';

/// Read-only app environment attached to every feedback submission so the
/// triage backend can reproduce a report without asking the user. Built once
/// at the composition root from `AppBuildInfo` + `PlatformCapabilities` +
/// the active locale, then handed to the controller; a widget never fills it.
///
/// Contains no PII: version / platform / locale only. Never auto-attach
/// account identifiers (feedback spec — PII in metadata note).
@immutable
final class FeedbackAppMetadata {
  const FeedbackAppMetadata({
    required this.appVersion,
    required this.platform,
    required this.locale,
  });

  /// Installed build version (for example `1.0.0+1`). Surfaced verbatim from
  /// `AppBuildInfo` so the triage backend can reproduce against the exact
  /// release.
  final String appVersion;

  /// Lowercase platform name from `PlatformCapabilities.platform`
  /// (`ios`, `android`, `macos`, ...). No device identifiers.
  final String platform;

  /// Active BCP-47 locale tag (for example `en`, `ar`, `zh-Hans`) read from the
  /// active `AppLocale` at composition time.
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
/// to `SettingsStore` under the `feedback.draft.*` keys so a half-written
/// report survives backgrounding. Cleared only on a confirmed `accepted`
/// result — a failed submit retains the text for retry (feedback spec — draft
/// persistence scope note).
///
/// The optional [email] is trimmed at the controller boundary before it ever
/// reaches this value; the [message] is preserved verbatim (grapheme-aware
/// UI handles display). [includeScreenshot] is the user's *intent* — the
/// actual screenshot bytes are attached by the transport only when a real
/// backend is configured; with the Noop default the toggle is inert (feedback
/// spec — screenshot capture needs a real backend note).
@immutable
final class FeedbackDraft {
  const FeedbackDraft({
    this.message = '',
    this.email,
    this.includeScreenshot = false,
  });

  const FeedbackDraft.empty() : message = '', email = null, includeScreenshot = false;

  final String message;

  /// Optional reply-to address. Trimmed + shape-validated before assignment;
  /// `null` when the user left the field blank (the field is optional).
  final String? email;

  /// User intent to attach a screenshot. Inert under the Noop transport (no
  /// backend captures bytes); a real transport reads this to gate capture.
  final bool includeScreenshot;

  /// `true` when there is nothing worth persisting. Used by the controller to
  /// skip the debounced write when the draft collapses back to empty.
  bool get isEmpty => message.trim().isEmpty && email == null && !includeScreenshot;

  /// `true` when the message has non-whitespace content. The submit button +
  /// the controller's `submit()` gate on this so an empty report can never
  /// reach the transport.
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
      // "clear". The explicit [clearEmail] flag mirrors AttemptState's
      // `clearLockedUntil` + SettingsState's `followSystemLocale` pattern.
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

/// The normalized value emitted by the feedback sheet after native form
/// validation. Mirrors the auth `*FormValue` trio: a handwritten typed value
/// built from `save()` + the live draft, never a `Map`.
///
/// Carries the user input plus the `appMetadata` snapshot so the transport
/// payload (`FeedbackSubmission`) is derived in one step. The email is trimmed
/// at this boundary; the message is preserved verbatim. Per the feedback spec
/// the form value lists `message`, `email?`, `includeScreenshot`,
/// `appMetadata` — this is the canonical typed shape for those four.
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

  /// User intent to attach a screenshot.
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
