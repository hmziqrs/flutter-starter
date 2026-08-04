import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/app_spacing.dart';

class AuthFormHeader extends StatelessWidget {
  const AuthFormHeader({
    required this.title,
    required this.body,
    this.alerts = const [],
    super.key,
  });

  final String title;

  final String body;

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
