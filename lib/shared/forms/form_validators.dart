/// Pure, locale-agnostic form validators shared across every starter form.
///
/// These were extracted verbatim from the auth form support so that billing,
/// settings-entry, and feedback forms reuse the exact same policies. Each
/// validator keeps the `(value, messages)` signature: it never trims a value it
/// returns, and the feature supplies the localized message so the helper stays
/// copy-free.
///
/// Password values are intentionally **not** trimmed — the secret may contain
/// leading/trailing spaces; only the email shape policy trims before checking.
library;

/// Validates a required field without normalizing its value.
///
/// Returns [message] when [value] is `null` or empty, otherwise `null`. A
/// whitespace-only value is considered present (callers that want to reject
/// whitespace trim before calling).
String? validateRequired(String? value, String message) {
  return value == null || value.isEmpty ? message : null;
}

/// Validates the starter's deliberately small email-shape policy.
///
/// Trims [value] before checking that it contains an `@` (not at the start)
/// followed by a `.` in the domain tail (not immediately after the `@` and not
/// the final character). Returns [requiredMessage] for empty input and
/// [invalidMessage] for a malformed shape.
String? validateEmail(
  String? value, {
  required String requiredMessage,
  required String invalidMessage,
}) {
  if (value == null || value.isEmpty) return requiredMessage;
  final candidate = value.trim();
  final at = candidate.indexOf('@');
  final dot = candidate.lastIndexOf('.');
  if (at <= 0 || dot <= at + 1 || dot == candidate.length - 1) {
    return invalidMessage;
  }
  return null;
}

/// Validates the starter's static password policy without trimming the secret.
///
/// Requires at least 8 characters, one uppercase letter, and one digit. Returns
/// [requiredMessage] for empty input and [weakMessage] otherwise. The value is
/// checked literally — a space is a legitimate password character.
String? validatePassword(
  String? value, {
  required String requiredMessage,
  required String weakMessage,
}) {
  if (value == null || value.isEmpty) return requiredMessage;
  final hasUppercase = value.contains(RegExp('[A-Z]'));
  final hasNumber = value.contains(RegExp('[0-9]'));
  if (value.length < 8 || !hasUppercase || !hasNumber) return weakMessage;
  return null;
}
