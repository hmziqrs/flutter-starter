import 'package:flutter/material.dart';
import 'package:starter/shared/forms/form_validators.dart';
import 'package:starter/shared/forms/password_field_toggle.dart';
import 'package:starter/shared/forms/tv_editable_text_field.dart';
import 'package:starter/shared/widgets/app_tv_editable_field.dart';

AppTvEditableField passwordFormField({
  required Key activationKey,
  required Key fieldKey,
  required Key toggleKey,
  required String label,
  required TextEditingController controller,
  required FocusNode focusNode,
  required GlobalKey<FormFieldState<String>> formFieldKey,
  bool enabled = true,
  bool autofocus = false,
  String? forceErrorText,
  Widget? description,
  Iterable<String> autofillHints = const [AutofillHints.password],
  TextInputAction textInputAction = TextInputAction.next,
  FocusNode? nextFocusNode,
  VoidCallback? onSubmit,
}) {
  return tvEditableTextField(
    activationKey: activationKey,
    fieldKey: fieldKey,
    label: label,
    controller: controller,
    focusNode: focusNode,
    formFieldKey: formFieldKey,
    secure: true,
    validator: (value, translations) => validatePassword(
      value,
      requiredMessage: translations.validation.required(field: label),
      weakMessage: translations.validation.passwordWeak,
    ),
    enabled: enabled,
    autofocus: autofocus,
    forceErrorText: forceErrorText,
    description: description,
    autofillHints: autofillHints,
    textInputAction: textInputAction,
    suffixBuilder: buildPasswordToggle(key: toggleKey),
    nextFocusNode: nextFocusNode,
    onSubmit: onSubmit,
  );
}

AppTvEditableField confirmPasswordFormField({
  required Key activationKey,
  required Key fieldKey,
  required Key toggleKey,
  required String label,
  required TextEditingController controller,
  required FocusNode focusNode,
  required GlobalKey<FormFieldState<String>> formFieldKey,
  required TextEditingController matchTarget,
  bool enabled = true,
  bool autofocus = false,
  String? forceErrorText,
  Iterable<String> autofillHints = const [AutofillHints.newPassword],
  TextInputAction textInputAction = TextInputAction.done,
  VoidCallback? onSubmit,
}) {
  return tvEditableTextField(
    activationKey: activationKey,
    fieldKey: fieldKey,
    label: label,
    controller: controller,
    focusNode: focusNode,
    formFieldKey: formFieldKey,
    secure: true,
    validator: (value, translations) {
      final requiredError = validateRequired(
        value,
        translations.validation.required(field: label),
      );
      if (requiredError != null) return requiredError;
      if (value != matchTarget.text) {
        return translations.validation.passwordMismatch;
      }
      return null;
    },
    enabled: enabled,
    autofocus: autofocus,
    forceErrorText: forceErrorText,
    autofillHints: autofillHints,
    textInputAction: textInputAction,
    suffixBuilder: buildPasswordToggle(key: toggleKey),
    onSubmit: onSubmit,
  );
}
