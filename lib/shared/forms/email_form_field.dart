import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/forms/form_validators.dart';
import 'package:starter/shared/widgets/app_tv_editable_field.dart';

/// A shared email field for auth forms.
///
/// Wraps [AppTvEditableField] around an [FTextFormField.email] configured with
/// the canonical auth email chrome:
///   * autofill hints `[AutofillHints.username, AutofillHints.email]`,
///   * LTR text direction,
///   * [AutovalidateMode.onUserInteractionIfError],
///   * a clear-and-unfocus reset,
///   * the centralized [validateEmail] validator (messages sourced from
///     translations, using [label] as the field name).
///
/// The caller keeps control of focus navigation and submit-on-enter:
///   * pass [nextFocusNode] to wire the keyboard editing-complete flow to the
///     next field, and/or
///   * pass [onSubmit] to submit when the field's enter action fires.
///
/// The controller write-back for state restoration stays with the caller (see
/// `RestorableTextControllerBinding`).
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
  return AppTvEditableField(
    activationKey: activationKey,
    label: label,
    controller: controller,
    focusNode: focusNode,
    enabled: enabled,
    autofocus: autofocus,
    builder: (context, editorFocusNode, completeEditing) {
      final translations = context.t;
      return FTextFormField.email(
        key: fieldKey,
        formFieldKey: formFieldKey,
        control: .managed(controller: controller),
        focusNode: editorFocusNode,
        label: Text(label),
        textDirection: TextDirection.ltr,
        autofillHints: const [AutofillHints.username, AutofillHints.email],
        textInputAction: textInputAction,
        enabled: enabled,
        autovalidateMode: AutovalidateMode.onUserInteractionIfError,
        forceErrorText: forceErrorText,
        validator: (value) => validateEmail(
          value,
          requiredMessage: translations.validation.required(field: label),
          invalidMessage: translations.validation.email,
        ),
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
