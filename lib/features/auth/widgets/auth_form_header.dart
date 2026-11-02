import 'package:flutter/material.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/blocks/page_intro.dart';

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
    // The kit's page-intro composition (page-intro.svelte at the app type
    // scale) for the title/intro pair — the same 24 w500 tracking-tight title
    // over the muted 14 line every shell page opens with.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppPageIntro(title: title, description: body),
        for (final alert in alerts) ...[
          SizedBox(height: context.spacing.xl),
          alert,
        ],
        SizedBox(height: context.spacing.xl),
      ],
    );
  }
}
