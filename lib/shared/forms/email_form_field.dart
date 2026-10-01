import 'package:flutter/material.dart';
import 'package:starter/shared/forms/form_validators.dart';
import 'package:starter/shared/forms/tv_editable_text_field.dart';
import 'package:starter/shared/widgets/app_tv_editable_field.dart';

AppTvEditableField emailFormField({
  required Key activationKey,
  required Key fieldKey,
  required String label,
  required TextEditingController controller,
  required FocusNode focusNode,
  required GlobalKey<FormFieldState<String>> formFieldKey,
  FocusNode? nextFocusNode,
  bool enabled = true,
  bool autofocus = false,
  String? forceErrorText,
  TextInputAction? textInputAction,
  VoidCallback? onSubmit,
}) {
  return tvEditableTextField(
    activationKey: activationKey,
    fieldKey: fieldKey,
    label: label,
    controller: controller,
    focusNode: focusNode,
    formFieldKey: formFieldKey,
    secure: false,
    validator: (value, translations) => validateEmail(
      value,
      requiredMessage: translations.validation.required(field: label),
      invalidMessage: translations.validation.email,
    ),
    enabled: enabled,
    autofocus: autofocus,
    forceErrorText: forceErrorText,
    textInputAction: textInputAction,
    nextFocusNode: nextFocusNode,
    onSubmit: onSubmit,
  );
}
