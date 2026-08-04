import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/forms/form_validators.dart';
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
