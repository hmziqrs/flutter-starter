/// Pass order matters (patterns overlap); card runs are Luhn-gated so non-card digit IDs survive.
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

  static final RegExp _email = RegExp(
    r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}\b',
  );

  static final RegExp _phoneE164 = RegExp(r'\+[1-9]\d{6,14}');

  static final RegExp _pan = RegExp(r'\b(?:\d[ -]?){12,18}\d\b');

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
