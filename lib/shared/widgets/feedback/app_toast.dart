import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';

/// The severity of an `AppToast`. Maps to a pinned `FToastVariant` + leading
/// icon + accessible label so every call site renders the same severity style.
///
/// Adding a value is a compile error in `_resolveTitle` / `_presentation` until
/// it is deliberately styled (audit #7: exhaustive switch, no `dynamic`).
enum ToastSeverity {
  /// A positive outcome. Renders the primary toast variant with a check icon;
  /// the title defaults to `common.success`.
  success,

  /// Neutral, non-urgent information. Renders the primary toast variant with an
  /// info icon. There is no canonical default title — the caller supplies one,
  /// or the `AppToast.show` message is promoted to the title.
  info,

  /// A recoverable warning. Renders the destructive toast variant with an alert
  /// icon. The caller supplies the title (or the message is promoted to it).
  warning,

  /// An operation failed or has no backend. Renders the destructive toast
  /// variant with a circle-alert icon; the title defaults to `common.error`.
  /// This is the severity used to surface `common.notConnected` for a
  /// no-backend action — never `ToastSeverity.success` (audit #13: no faked
  /// success).
  error,
}

/// A thin ergonomic wrapper over the `FToaster` already mounted at the root
/// (`MaterialApp.router`'s `builder:` in `lib/app/app.dart`).
///
/// Pins severity → `FToastVariant` + leading icon + accessible label and
/// localizes the default `common.success` / `common.error` titles, so callers
/// stop hand-rolling `showFToast(...)` boilerplate and the no-backend error
/// surface looks identical everywhere it appears.
///
/// The wrapper is a pure presentational helper:
/// - No providers, no Riverpod, no plugin calls — it forwards straight to
///   `showFToast`, which throws if no `FToaster` ancestor is mounted.
/// - Enter/exit motion is ForUI-native (the `FToaster` manages the route
///   animation). There is no custom transition here, so `AppMotion` is not
///   referenced; the auto-dismiss timer fires regardless of animation, so
///   reduce-motion users still see the toast mount and dismiss (audit #5).
/// - Navigation is never gated on toast state — [show] returns synchronously
///   with the `FToasterEntry`.
class AppToast {
  const AppToast._();

  /// Shows a localized toast of [severity].
  ///
  /// - [message] is always shown. For `ToastSeverity.success` / `error` it
  ///   becomes the toast description under the default title; for
  ///   `ToastSeverity.info` / `warning` without an explicit [title] it is
  ///   promoted to the title and no description is rendered.
  /// - [title] overrides the default (`common.success` / `common.error`).
  ///   Required in practice for info / warning; ignored-promoted when null.
  /// - [duration] defaults to 5s (the `showFToast` default). Pass `null` for a
  ///   persistent toast the user must dismiss — used for the no-backend error
  ///   surface so a transient timeout never hides the "not connected" message.
  /// - [onDismiss] fires once when the toast leaves the screen.
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
      // No canonical default title for info / warning: promote the message.
      ToastSeverity.info => message,
      ToastSeverity.warning => message,
    };
  }

  /// Exhaustive severity → visual mapping. The colors track the ForUI theme so
  /// the icon reads correctly in light/dark + high-contrast. `success` / `info`
  /// use the primary palette; `warning` / `error` use the destructive palette,
  /// matching the announcement-banner convention.
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

/// Resolved visual presentation for a `ToastSeverity`. Constructed eagerly
/// inside `AppToast.show` once the resolved title + theme colors are known, so
/// the record carries plain values (no function members, no `dynamic`).
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
