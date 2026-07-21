import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';

/// A form field's state, location, and focus target in visual order.
typedef AuthInvalidFieldTarget = ({
  FormFieldState<Object?>? field,
  BuildContext? context,
  FocusNode focusNode,
});

/// Validates a required authentication field without normalizing its value.
String? validateAuthRequired(String? value, String message) {
  return value == null || value.isEmpty ? message : null;
}

/// Validates the starter's deliberately small email-shape policy.
String? validateAuthEmail(
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

/// Validates the starter's static password policy without trimming the secret.
String? validateAuthPassword(
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

/// Builds the localized visibility control used by ForUI password fields.
FPasswordFieldIconBuilder<FTextFieldStyle> buildAuthPasswordToggle({required Key key}) {
  return (context, style, obscure, variants) {
    final disabled = variants.contains(FTextFieldVariant.disabled);
    final label = obscure.value
        ? context.t.auth.common.showPassword
        : context.t.auth.common.hidePassword;
    return Padding(
      padding: style.obscureButtonPadding,
      child: FButton.icon(
        key: key,
        style: style.obscureButtonStyle,
        semanticsLabel: label,
        onPress: disabled ? null : () => obscure.value = !obscure.value,
        child: obscure.value
            ? context.theme.icons.eye(context)
            : context.theme.icons.eyeClosed(context),
      ),
    );
  };
}

/// Reveals and focuses the first invalid field in explicit visual order.
Future<void> revealFirstAuthInvalid(
  Set<FormFieldState<Object?>> invalidFields, {
  required Iterable<AuthInvalidFieldTarget> orderedTargets,
  required bool Function() isMounted,
}) async {
  for (final target in orderedTargets) {
    final field = target.field;
    final fieldContext = target.context;
    if (field == null || fieldContext == null || !invalidFields.contains(field)) {
      continue;
    }
    await Scrollable.ensureVisible(fieldContext, alignment: 0.2);
    if (isMounted()) target.focusNode.requestFocus();
    return;
  }
}
