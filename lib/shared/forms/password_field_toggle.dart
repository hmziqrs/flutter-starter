import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';

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
