import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/forms/form_validators.dart';
import 'package:starter/shared/forms/password_field_toggle.dart';
import 'package:starter/shared/widgets/app_tv_editable_field.dart';

/// A shared password field for auth forms (login or "new password" inputs).
///
/// Wraps [AppTvEditableField] (secure) around an [FTextFormField.password] with:
///   * the show / hide toggle from [buildPasswordToggle],
///   * [AutovalidateMode.onUserInteractionIfError],
///   * a clear-and-unfocus reset,
///   * the centralized [validatePassword] validator (messages sourced from
///     translations, using [label] as the field name).
///
/// Pass [autofillHints] to select e.g. [AutofillHints.newPassword] (it defaults
/// to [AutofillHints.password], matching the underlying [FTextFormField.password]
/// constructor). Pass [nextFocusNode] to wire editing-complete to the next field,
/// and/or [onSubmit] to submit on the field's enter action.
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
  return AppTvEditableField(
    activationKey: activationKey,
    label: label,
    controller: controller,
    focusNode: focusNode,
    enabled: enabled,
    secure: true,
    autofocus: autofocus,
    builder: (context, editorFocusNode, completeEditing) {
      final translations = context.t;
      return FTextFormField.password(
        key: fieldKey,
        formFieldKey: formFieldKey,
        control: .managed(controller: controller),
        focusNode: editorFocusNode,
        label: Text(label),
        description: description,
        autofillHints: autofillHints,
        textInputAction: textInputAction,
        enabled: enabled,
        autovalidateMode: AutovalidateMode.onUserInteractionIfError,
        forceErrorText: forceErrorText,
        validator: (value) => validatePassword(
          value,
          requiredMessage: translations.validation.required(field: label),
          weakMessage: translations.validation.passwordWeak,
        ),
        suffixBuilder: buildPasswordToggle(key: toggleKey),
        onEditingComplete: nextFocusNode == null
            ? null
            : () => completeEditing(nextFocusNode: nextFocusNode),
        onSubmit: onSubmit == null
            ? null
            : (_) {
                completeEditing();
                onSubmit();
              },
        onReset: () {
          controller.clear();
          focusNode.unfocus();
        },
      );
    },
  );
}

/// A shared confirm-password field for auth forms.
///
/// Like [passwordFormField] but the validator additionally requires the entered
/// value to match [matchTarget]'s current text, reporting the mismatch message
/// from translations. Confirm is the last field, so it exposes [onSubmit] only
/// (no next-focus wiring). [autofillHints] defaults to [AutofillHints.newPassword]
/// and [textInputAction] defaults to [TextInputAction.done].
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
  return AppTvEditableField(
    activationKey: activationKey,
    label: label,
    controller: controller,
    focusNode: focusNode,
    enabled: enabled,
    secure: true,
    autofocus: autofocus,
    builder: (context, editorFocusNode, completeEditing) {
      final translations = context.t;
      return FTextFormField.password(
        key: fieldKey,
        formFieldKey: formFieldKey,
        control: .managed(controller: controller),
        focusNode: editorFocusNode,
        label: Text(label),
        autofillHints: autofillHints,
        textInputAction: textInputAction,
        enabled: enabled,
        autovalidateMode: AutovalidateMode.onUserInteractionIfError,
        forceErrorText: forceErrorText,
        validator: (value) {
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
        suffixBuilder: buildPasswordToggle(key: toggleKey),
        onSubmit: onSubmit == null
            ? null
            : (_) {
                completeEditing();
                onSubmit();
              },
        onReset: () {
          controller.clear();
          focusNode.unfocus();
        },
      );
    },
  );
}
