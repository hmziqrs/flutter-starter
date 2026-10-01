import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/widgets/app_tv_editable_field.dart';

/// Builds an [AppTvEditableField] wrapping a managed ForUI text form field with
/// shared autovalidation, next-focus chaining, submit, and clear-and-unfocus
/// reset behavior. [secure] selects `FTextFormField.password` (and [AppTvEditableField.secure]);
/// otherwise `FTextFormField.email` with LTR text direction is used.
AppTvEditableField tvEditableTextField({
  required Key activationKey,
  required Key fieldKey,
  required String label,
  required TextEditingController controller,
  required FocusNode focusNode,
  required GlobalKey<FormFieldState<String>> formFieldKey,
  required bool secure,
  required String? Function(String? value, Translations translations) validator,
  bool enabled = true,
  bool autofocus = false,
  String? forceErrorText,
  Iterable<String>? autofillHints,
  TextInputAction? textInputAction,
  Widget? description,
  FPasswordFieldIconBuilder<FTextFieldStyle>? suffixBuilder,
  FocusNode? nextFocusNode,
  VoidCallback? onSubmit,
}) {
  return AppTvEditableField(
    activationKey: activationKey,
    label: label,
    controller: controller,
    focusNode: focusNode,
    enabled: enabled,
    secure: secure,
    autofocus: autofocus,
    builder: (context, editorFocusNode, completeEditing) {
      final translations = context.t;
      String? validate(String? value) => validator(value, translations);
      void reset() {
        controller.clear();
        focusNode.unfocus();
      }

      void Function()? editingComplete;
      if (nextFocusNode case final node?) {
        editingComplete = () => completeEditing(nextFocusNode: node);
      }
      void Function(String)? submit;
      if (onSubmit case final callback?) {
        submit = (_) {
          completeEditing();
          callback();
        };
      }

      if (secure) {
        return FTextFormField.password(
          key: fieldKey,
          formFieldKey: formFieldKey,
          control: .managed(controller: controller),
          focusNode: editorFocusNode,
          label: Text(label),
          description: description,
          autofillHints: autofillHints ?? const [AutofillHints.password],
          textInputAction: textInputAction ?? TextInputAction.next,
          enabled: enabled,
          autovalidateMode: AutovalidateMode.onUserInteractionIfError,
          forceErrorText: forceErrorText,
          validator: validate,
          suffixBuilder: suffixBuilder,
          onEditingComplete: editingComplete,
          onSubmit: submit,
          onReset: reset,
        );
      }
      return FTextFormField.email(
        key: fieldKey,
        formFieldKey: formFieldKey,
        control: .managed(controller: controller),
        focusNode: editorFocusNode,
        label: Text(label),
        textDirection: TextDirection.ltr,
        autofillHints: autofillHints ?? const [AutofillHints.username, AutofillHints.email],
        textInputAction: textInputAction,
        enabled: enabled,
        autovalidateMode: AutovalidateMode.onUserInteractionIfError,
        forceErrorText: forceErrorText,
        validator: validate,
        onEditingComplete: editingComplete,
        onSubmit: submit,
        onReset: reset,
      );
    },
  );
}
