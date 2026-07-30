import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';

/// The severity of an `AppToast`. Maps to a pinned `FToastVariant` + leading
/// icon + accessible label so every call site renders the same severity style.
enum ToastSeverity {
  /// A positive outcome. Title defaults to `common.success`.
  success,

  /// Neutral, non-urgent information. No canonical default title — the caller
  /// supplies one, or the message is promoted to the title.
  info,

  /// A recoverable warning. The caller supplies the title (or the message is
  /// promoted to it).
  warning,

  /// An operation failed or has no backend. Title defaults to `common.error`.
  error,
}

/// A thin ergonomic wrapper over the `FToaster` already mounted at the root
/// (`MaterialApp.router`'s `builder:` in `lib/app/app.dart`).
///
/// Pins severity → `FToastVariant` + leading icon + accessible label and
/// localizes the default `common.success` / `common.error` titles.
class AppToast {
  const AppToast._();

  /// Shows a localized toast of [severity].
  ///
  /// [message] is always shown; for `success`/`error` it becomes the
  /// description under the default title, for `info`/`warning` without an
  /// explicit [title] it is promoted to the title. [duration] defaults to 5s;
  /// pass `null` for a persistent toast the user must dismiss.
  ///
  /// Returns the underlying `FToasterEntry` for programmatic dismissal.
  static FToasterEntry show(
    BuildContext context, {
    required ToastSeverity severity,
    required String message,
    String? title,
    Duration? duration = const Duration(seconds: 5),
    VoidCallback? onDismiss,
  }) {
    final translations = context.t;
    final resolvedTitle = _resolveTitle(severity, title, message, translations);
    final showDescription =
        title != null || severity == ToastSeverity.success || severity == ToastSeverity.error;
    final presentation = _presentation(context, severity, resolvedTitle);
    return showFToast(
      context: context,
      variant: presentation.variant,
      icon: Icon(
        presentation.icon,
        size: 18,
        color: presentation.iconColor,
        semanticLabel: presentation.semanticLabel,
      ),
      title: Text(resolvedTitle),
      description: showDescription ? Text(message) : null,
      duration: duration,
      onDismiss: onDismiss,
    );
  }

  static String _resolveTitle(
    ToastSeverity severity,
    String? title,
    String message,
    Translations translations,
  ) {
    if (title != null) {
      return title;
    }
    return switch (severity) {
      ToastSeverity.success => translations.common.success,
      ToastSeverity.error => translations.common.error,
      ToastSeverity.info => message,
      ToastSeverity.warning => message,
    };
  }

  /// Exhaustive severity → visual mapping. `success`/`info` use the primary
  /// palette; `warning`/`error` use the destructive palette.
  static _ToastPresentation _presentation(
    BuildContext context,
    ToastSeverity severity,
    String resolvedTitle,
  ) {
    final translations = context.t;
    final colors = FTheme.of(context).colors;
    return switch (severity) {
      ToastSeverity.success => _ToastPresentation(
        variant: FToastVariant.primary,
        icon: FLucideIcons.circleCheck,
        iconColor: colors.primary,
        semanticLabel: translations.common.success,
      ),
      ToastSeverity.info => _ToastPresentation(
        variant: FToastVariant.primary,
        icon: FLucideIcons.info,
        iconColor: colors.primary,
        semanticLabel: resolvedTitle,
      ),
      ToastSeverity.warning => _ToastPresentation(
        variant: FToastVariant.destructive,
        icon: FLucideIcons.triangleAlert,
        iconColor: colors.error,
        semanticLabel: resolvedTitle,
      ),
      ToastSeverity.error => _ToastPresentation(
        variant: FToastVariant.destructive,
        icon: FLucideIcons.circleAlert,
        iconColor: colors.error,
        semanticLabel: translations.common.error,
      ),
    };
  }
}

/// Resolved visual presentation for a `ToastSeverity`.
class _ToastPresentation {
  const _ToastPresentation({
    required this.variant,
    required this.icon,
    required this.iconColor,
    required this.semanticLabel,
  });

  final FToastVariant variant;
  final IconData icon;
  final Color iconColor;
  final String semanticLabel;
}
