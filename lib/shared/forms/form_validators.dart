String? validateRequired(String? value, String message) {
  return value == null || value.isEmpty ? message : null;
}

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
