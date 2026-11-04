import 'package:flutter/material.dart';
import 'package:starter/shared/theme/app_spacing.dart';

/// The notices at the top of an entry-flow form. `AuthPageScaffold` owns the
/// page's title and description, so a form opens with its alerts, if any, and
/// then its first field.
class AuthFormAlerts extends StatelessWidget {
  const AuthFormAlerts({required this.alerts, super.key});

  final List<Widget> alerts;

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();
    final gap = context.spacing.lg;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final alert in alerts) ...[alert, SizedBox(height: gap)],
      ],
    );
  }
}
