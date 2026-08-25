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
    Key? dialogKey,
    Key? cancelKey,
    Key? actionKey,
    bool autofocusCancel = false,
    bool flexibleActions = false,
    double titleBodySpacing = AppSpacing.sm,
  }) {
    final translations = context.t;
    final action = confirmLabel ?? _defaultActionLabel(intent, translations);
    final cancel = cancelLabel ?? translations.common.cancel;
    final semantic = semanticsLabel ?? title;
    final resolvedDialogKey = dialogKey ?? const ValueKey('app-confirmation-dialog');
    final resolvedCancelKey = cancelKey ?? const ValueKey('app-confirmation-cancel');
    final resolvedActionKey = actionKey ?? const ValueKey('app-confirmation-action');
    final contentBuilder = flexibleActions ? _flexibleButtonContent : FButton.defaultContentBuilder;

    return showFDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext, style, animation) => EscapeDismissibleOverlay(
        child: FDialog(
          key: resolvedDialogKey,
          animation: animation,
          semanticsLabel: semantic,
          builder: (_, _) => Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: style.titleTextStyle),
                SizedBox(height: titleBodySpacing),
                Text(body, style: style.bodyTextStyle),
                const SizedBox(height: AppSpacing.xl),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    FButton(
                      key: resolvedCancelKey,
                      variant: FButtonVariant.outline,
                      mainAxisSize: MainAxisSize.min,
                      autofocus: autofocusCancel,
                      builder: contentBuilder,
                      onPress: () => Navigator.of(dialogContext).pop(false),
                      child: Text(cancel),
                    ),
                    FButton(
                      key: resolvedActionKey,
                      variant: _actionVariant(intent),
                      mainAxisSize: MainAxisSize.min,
                      builder: contentBuilder,
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

Widget _flexibleButtonContent(
  BuildContext _,
  FButtonStyle _,
  TextStyle _,
  IconThemeData _,
  FCircularProgressStyle _,
  Widget? child,
) => Flexible(child: child!);
