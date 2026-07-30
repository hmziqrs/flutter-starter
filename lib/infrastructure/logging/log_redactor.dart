/// Single choke point that scrubs PII from log messages and structured
/// context before they reach Talker / crash reporters.
///
/// [redactText] runs its passes in a deliberate order so the most specific
/// patterns win: bearer tokens, then `key=value` assignments, then query
/// params, then email (before phone, so a `+`-alias local part isn't
/// partially redacted), then Luhn-gated card numbers (non-Luhn digit runs
/// survive, to avoid eating order/diagnostic IDs), then E.164 phone numbers,
/// then standalone JWT bodies last (so a `Bearer <jwt>` is already gone).
final class LogRedactor {
  const LogRedactor();

  static const replacement = '[REDACTED]';

  static final RegExp _sensitiveKey = RegExp(
    r'(^|[_\-])('
    'authorization|cookie|password|passcode|token|secret|otp|code|'
    r'api[_\-]?key|email|phone|pan|card'
    r')($|[_\-])',
    caseSensitive: false,
  );
  static final RegExp _bearerToken = RegExp(
    r'\bBearer\s+[^\s,;]+',
    caseSensitive: false,
  );
  static final RegExp _sensitiveAssignment = RegExp(
    r'\b(token|password|passcode|secret|otp|api[_\-]?key)=([^\s&,;]+)',
    caseSensitive: false,
  );
  static final RegExp _queryStringToken = RegExp(
    '([?&])('
    r'access_token|refresh_token|id_token|api[_\-]?key|token|secret|password'
    r')=([^&#\s]+)',
    caseSensitive: false,
  );

  /// Email address: `local@domain.tld`. The delimiter-framed [_sensitiveKey]
  /// handles structured keys; this catches emails embedded in free text.
  static final RegExp _email = RegExp(
    r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}\b',
  );

  /// E.164 phone number: `+` then 7-15 digits (leading digit non-zero).
  static final RegExp _phoneE164 = RegExp(r'\+[1-9]\d{6,14}');

  /// PAN candidate: 13-19 digits with optional single space/dash separators,
  /// Luhn-checked in the callback so non-card digit runs survive. `\b`
  /// anchoring prevents matches inside larger tokens.
  static final RegExp _pan = RegExp(r'\b(?:\d[ -]?){12,18}\d\b');

  /// JWT body: three dot-separated base64url segments, anchored on `eyJ`
  /// (the base64 of `{"`) to avoid matching version strings like `1.2.3`.
  static final RegExp _jwtPayload = RegExp(
    r'\beyJ[A-Za-z0-9_-]*\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\b',
  );

  String redactText(String text) {
    return text
        .replaceAllMapped(_bearerToken, (match) => 'Bearer $replacement')
        .replaceAllMapped(
          _sensitiveAssignment,
          (match) => '${match.group(1)}=$replacement',
        )
        .replaceAllMapped(
          _queryStringToken,
          (match) => '${match.group(1)}${match.group(2)}=$replacement',
        )
        .replaceAllMapped(_email, (match) => replacement)
        .replaceAllMapped(_pan, (match) {
          final digits = match.group(0)!.replaceAll(_separator, '');
          return _isLuhnValid(digits) ? replacement : match.group(0)!;
        })
        .replaceAllMapped(_phoneE164, (match) => replacement)
        .replaceAllMapped(_jwtPayload, (match) => replacement);
  }

  Map<String, Object?> redactContext(Map<String, Object?> context) {
    return context.map(
      (key, value) => MapEntry(
        key,
        _sensitiveKey.hasMatch(key) ? replacement : _redactValue(value),
      ),
    );
  }

  Object? _redactValue(Object? value) {
    return switch (value) {
      null => null,
      String() => redactText(value),
      Map<String, Object?>() => redactContext(value),
      Iterable<Object?>() => value.map(_redactValue).toList(growable: false),
      _ => value,
    };
  }

  static final RegExp _separator = RegExp('[ -]');

  /// Luhn checksum used to gate [_pan] matches so non-card digit runs
  /// (order IDs, diagnostic codes) survive redaction.
  static bool _isLuhnValid(String digits) {
    var sum = 0;
    var alternate = false;
    for (var i = digits.length - 1; i >= 0; i--) {
      var value = digits.codeUnitAt(i) - 0x30;
      if (alternate) {
        value *= 2;
        if (value > 9) {
          value -= 9;
        }
      }
      sum += value;
      alternate = !alternate;
    }
    return sum > 0 && sum % 10 == 0;
  }
}
