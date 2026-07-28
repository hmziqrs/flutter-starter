import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';

/// Builds the localized visibility control used by ForUI password fields.
///
/// Returns a [FPasswordFieldIconBuilder] that toggles `obscure.value` and swaps
/// the eye/eye-closed icon, with a localized [Semantics] label drawn from the
/// existing `auth.common.showPassword` / `hidePassword` copy. The icon is
/// disabled alongside the field (when [FTextFieldVariant.disabled] is present)
/// so the toggle cannot flip a read-only secret.
FPasswordFieldIconBuilder<FTextFieldStyle> buildPasswordToggle({required Key key}) {
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
