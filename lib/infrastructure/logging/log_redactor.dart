final class LogRedactor {
  const LogRedactor();

  static const replacement = '[REDACTED]';

  static final RegExp _sensitiveKey = RegExp(
    r'(^|[_\-])(authorization|cookie|password|passcode|token|secret|otp|code|api[_\-]?key)($|[_\-])',
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

  String redactText(String text) {
    return text
        .replaceAllMapped(_bearerToken, (match) => 'Bearer $replacement')
        .replaceAllMapped(
          _sensitiveAssignment,
          (match) => '${match.group(1)}=$replacement',
        );
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
}
