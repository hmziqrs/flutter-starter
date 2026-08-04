import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/app_spacing.dart';

/// The title + body + alerts header shared by every auth form.
///
/// Centralizes the spacing-token contract duplicated across the auth pages: a
/// `display.xl2` title, [AppSpacing.md], a `body.md` body, then each alert
/// preceded by [AppSpacing.xl], and finally a trailing [AppSpacing.xl] before
/// the first field. [alerts] must be pre-filtered (non-null) by the page — pass
/// only the alerts that should be visible, in display order.
///
/// The column uses [MainAxisSize.min] so it nests safely inside the form's
/// outer `Column` without claiming unbounded vertical space.
class AuthFormHeader extends StatelessWidget {
  const AuthFormHeader({
    required this.title,
    required this.body,
    this.alerts = const [],
    super.key,
  });

  /// The header title text, rendered with `typography.display.xl2`.
  final String title;

  /// The header body text, rendered with `typography.body.md`.
  final String body;

  /// The feedback/status alerts to show beneath the body, each preceded by
  /// [AppSpacing.xl]. Pass only the alerts that should be visible.
  final List<Widget> alerts;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: context.theme.typography.display.xl2),
        const SizedBox(height: AppSpacing.md),
        Text(body, style: context.theme.typography.body.md),
        for (final alert in alerts) ...[
          const SizedBox(height: AppSpacing.xl),
          alert,
        ],
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}
