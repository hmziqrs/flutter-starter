/// Aliasing facade over the canonical shared form helpers in
/// `lib/shared/forms/`, kept so the auth pages resolve the Auth-prefixed
/// symbols they were written against. New features should import
/// `package:starter/shared/forms/*` directly.
library;

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/forms/form_field_reveal.dart';
import 'package:starter/shared/forms/form_validators.dart';
import 'package:starter/shared/forms/password_field_toggle.dart';

/// Alias for [InvalidFieldTarget] (the canonical shared type).
typedef AuthInvalidFieldTarget = InvalidFieldTarget;

/// Alias for [validateRequired].
String? validateAuthRequired(String? value, String message) => validateRequired(value, message);

/// Alias for [validateEmail].
String? validateAuthEmail(
  String? value, {
  required String requiredMessage,
  required String invalidMessage,
}) => validateEmail(
  value,
  requiredMessage: requiredMessage,
  invalidMessage: invalidMessage,
);

/// Alias for [validatePassword].
String? validateAuthPassword(
  String? value, {
  required String requiredMessage,
  required String weakMessage,
}) => validatePassword(
  value,
  requiredMessage: requiredMessage,
  weakMessage: weakMessage,
);

/// Alias for [buildPasswordToggle].
FPasswordFieldIconBuilder<FTextFieldStyle> buildAuthPasswordToggle({required Key key}) =>
    buildPasswordToggle(key: key);

/// Alias for [revealFirstInvalid].
Future<void> revealFirstAuthInvalid(
  Set<FormFieldState<Object?>> invalidFields, {
  required Iterable<AuthInvalidFieldTarget> orderedTargets,
  required bool Function() isMounted,
}) => revealFirstInvalid(
  invalidFields,
  orderedTargets: orderedTargets,
  isMounted: isMounted,
);
