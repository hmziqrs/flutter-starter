import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/escape_dismissible_overlay.dart';

enum ConfirmationIntent {
  confirm,

  destroy,
}

class AppConfirmationDialog {
  const AppConfirmationDialog._();

  static Future<bool?> show(
    BuildContext context, {
    required ConfirmationIntent intent,
    required String title,
    required String body,
    String? confirmLabel,
    String? cancelLabel,
    String? semanticsLabel,
  }) {
    final translations = context.t;
    final action = confirmLabel ?? _defaultActionLabel(intent, translations);
    final cancel = cancelLabel ?? translations.common.cancel;
    final semantic = semanticsLabel ?? title;

    return showFDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext, style, animation) => EscapeDismissibleOverlay(
        child: FDialog(
          key: const ValueKey('app-confirmation-dialog'),
          animation: animation,
          semanticsLabel: semantic,
          builder: (_, _) => Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: style.titleTextStyle),
                const SizedBox(height: AppSpacing.sm),
                Text(body, style: style.bodyTextStyle),
                const SizedBox(height: AppSpacing.xl),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    FButton(
                      key: const ValueKey('app-confirmation-cancel'),
                      variant: FButtonVariant.outline,
                      mainAxisSize: MainAxisSize.min,
                      onPress: () => Navigator.of(dialogContext).pop(false),
                      child: Text(cancel),
                    ),
                    FButton(
                      key: const ValueKey('app-confirmation-action'),
                      variant: _actionVariant(intent),
                      mainAxisSize: MainAxisSize.min,
                      onPress: () => Navigator.of(dialogContext).pop(true),
                      child: Text(action),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _defaultActionLabel(ConfirmationIntent intent, Translations translations) {
    return switch (intent) {
      ConfirmationIntent.confirm => translations.common.confirm,
      ConfirmationIntent.destroy => translations.common.discard,
    };
  }

  static FButtonVariant _actionVariant(ConfirmationIntent intent) {
    return switch (intent) {
      ConfirmationIntent.confirm => FButtonVariant.primary,
      ConfirmationIntent.destroy => FButtonVariant.destructive,
    };
  }
}
