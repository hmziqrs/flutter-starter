import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Immutable description of a single auth feedback [FAlert].
///
/// Pages resolve their (page-specific) presentation status into one of these,
/// then hand it to [AuthFeedbackAlert] so the [FAlert] construction stays
/// uniform across login, OTP, registration, and the password flows. Carrying
/// [key] on the spec keeps the alert's `ValueKey` (e.g.
/// `ValueKey('auth-login-invalid')`) on the rendered [FAlert], preserving the
/// identifiers tests and golden flows key against.
class AuthFeedbackAlertSpec {
  const AuthFeedbackAlertSpec({
    required this.title,
    this.variant = .primary,
    this.subtitle,
    this.icon,
    this.key,
  });

  /// The key forwarded to the rendered [FAlert].
  final Key? key;

  /// The alert variant. Defaults to [FAlertVariant.primary], matching [FAlert].
  final FAlertVariant variant;

  /// The alert title.
  final Widget title;

  /// Optional alert subtitle.
  final Widget? subtitle;

  /// Optional leading icon.
  final Widget? icon;
}

/// Renders an auth feedback alert from an [AuthFeedbackAlertSpec].
///
/// Include this in the form's alert list only when the page's status resolves
/// to a spec. Use [AuthFeedbackAlert.forStatus] to resolve a status and get
/// back `null` when no alert applies (idle / submitting / etc.), so the header
/// can skip it entirely.
class AuthFeedbackAlert<S> extends StatelessWidget {
  const AuthFeedbackAlert({required this.spec, super.key});

  /// Creates an alert for [status] using [specFor], or `null` when the page
  /// maps the status to no spec (e.g. idle / submitting).
  ///
  /// [specFor] is a closure so pages can fold in runtime-derived copy such as
  /// a fixture success message or the live lockout-seconds remaining.
  static Widget? forStatus<S>({
    required S status,
    required AuthFeedbackAlertSpec? Function(S status) specFor,
  }) {
    final spec = specFor(status);
    if (spec == null) return null;
    return AuthFeedbackAlert<S>(spec: spec);
  }

  final AuthFeedbackAlertSpec spec;

  @override
  Widget build(BuildContext context) {
    return FAlert(
      key: spec.key,
      variant: spec.variant,
      title: spec.title,
      subtitle: spec.subtitle,
      icon: spec.icon,
    );
  }
}

/// Renders the "attempts remaining" alert shared by the login and OTP pages.
///
/// Use [AuthAttemptsRemainingAlert.maybe] to honor the shared visibility rule
/// (show only when `remaining > 0` and not locked) and get back `null`
/// otherwise, so the header can skip it. This centralizes the
/// `remaining <= 0 || status == locked` predicate that login and OTP duplicate.
class AuthAttemptsRemainingAlert extends StatelessWidget {
  const AuthAttemptsRemainingAlert({
    required this.remaining,
    required this.titleFor,
    super.key,
    this.alertKey,
  });

  /// Returns the attempts-remaining alert when [remaining] is positive and the
  /// surface is not [locked], otherwise `null`.
  static Widget? maybe({
    required int remaining,
    required bool locked,
    required Widget Function(int remaining) titleFor,
    Key? alertKey,
  }) {
    if (remaining <= 0 || locked) return null;
    return AuthAttemptsRemainingAlert(
      remaining: remaining,
      titleFor: titleFor,
      alertKey: alertKey,
    );
  }

  /// The number of attempts still remaining.
  final int remaining;

  /// Builds the alert title for the given remaining count.
  final Widget Function(int remaining) titleFor;

  /// The key forwarded to the rendered [FAlert].
  final Key? alertKey;

  @override
  Widget build(BuildContext context) {
    return FAlert(key: alertKey, title: titleFor(remaining));
  }
}
