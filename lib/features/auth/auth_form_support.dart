import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/forms/form_field_reveal.dart';
import 'package:starter/shared/forms/form_validators.dart';
import 'package:starter/shared/forms/password_field_toggle.dart';

typedef AuthInvalidFieldTarget = InvalidFieldTarget;

String? validateAuthRequired(String? value, String message) => validateRequired(value, message);

String? validateAuthEmail(
  String? value, {
  required String requiredMessage,
  required String invalidMessage,
}) => validateEmail(
  value,
  requiredMessage: requiredMessage,
  invalidMessage: invalidMessage,
);

String? validateAuthPassword(
  String? value, {
  required String requiredMessage,
  required String weakMessage,
}) => validatePassword(
  value,
  requiredMessage: requiredMessage,
  weakMessage: weakMessage,
);

FPasswordFieldIconBuilder<FTextFieldStyle> buildAuthPasswordToggle({required Key key}) =>
    buildPasswordToggle(key: key);

Future<void> revealFirstAuthInvalid(
  Set<FormFieldState<Object?>> invalidFields, {
  required Iterable<AuthInvalidFieldTarget> orderedTargets,
  required bool Function() isMounted,
}) => revealFirstInvalid(
  invalidFields,
  orderedTargets: orderedTargets,
  isMounted: isMounted,
);
