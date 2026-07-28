import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/escape_dismissible_overlay.dart';

/// The intent of an `AppConfirmationDialog`. Selects the action-button variant
/// and the localized action label — `confirm` for an affirmative primary
/// action, `destroy` for an irreversible / destructive one.
enum ConfirmationIntent {
  /// An affirmative, non-destructive action. Renders the primary `FButton` for
  /// the action and the outline `FButton` for cancel. Default action label is
  /// `common.confirm`; cancel is `common.cancel`.
  confirm,

  /// An irreversible / destructive action (e.g. discard unsaved edits, delete a
  /// row). Renders the destructive `FButton` for the action and the outline
  /// `FButton` for keep/cancel. Default action label is `common.discard`; the
  /// keep/cancel label is `common.cancel`.
  destroy,
}

/// A thin ergonomic wrapper over `showFDialog` + `FDialog` that pins intent →
/// `FButton` variant and localizes the confirm / cancel labels.
///
/// Wraps the dialog in `EscapeDismissibleOverlay` so Escape dismisses
/// consistently with every other modal in the app (audit #5: the Escape pop
/// runs through `Navigator.maybePop`, which completes regardless of any enter
/// / exit animation). The enter/exit transition itself is ForUI-native
/// (`FDialogRouteMotion`); no custom motion is introduced, so `AppMotion` is
/// not referenced and reduce-motion users get the framework's native shortcut.
///
/// Returns `true` if the user confirmed/destroyed, `false` if they cancelled,
/// and `null` if the dialog was dismissed via Escape (the
/// `EscapeDismissibleOverlay` calls `maybePop` without a result). Callers that
/// only care about confirmation treat `null` and `false` identically.
class AppConfirmationDialog {
  const AppConfirmationDialog._();

  /// Shows a modal confirmation dialog.
  ///
  /// - [intent] selects the action-button variant and the default action label.
  /// - [title] / [body] are the localized copy. [title] is also used as the
  ///   dialog's `semanticsLabel` unless [semanticsLabel] is supplied.
  /// - [confirmLabel] overrides the default action label (`common.confirm` for
  ///   `ConfirmationIntent.confirm`, `common.discard` for
  ///   `ConfirmationIntent.destroy`).
  /// - [cancelLabel] overrides the default cancel label (`common.cancel`).
  ///
  /// The dialog is NOT barrier-dismissible on tap (the existing discard
  /// prompts in `register_page` and `update_profile_page` set
  /// `barrierDismissible: false`); Escape still dismisses via
  /// `EscapeDismissibleOverlay`.
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
