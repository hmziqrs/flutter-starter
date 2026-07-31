import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/app_spacing.dart';

typedef StateViewAction = ({String label, VoidCallback onTap});

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    required this.title,
    required this.body,
    this.icon = FLucideIcons.inbox,
    this.action,
    super.key,
  });

  final String title;

  final String body;

  final IconData icon;

  final StateViewAction? action;

  @override
  Widget build(BuildContext context) {
    return FCard(
      key: const ValueKey('empty-state-view'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 32),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              key: const ValueKey('empty-state-view-title'),
              style: context.theme.cardStyle.titleTextStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              body,
              key: const ValueKey('empty-state-view-body'),
              style: context.theme.cardStyle.subtitleTextStyle,
              textAlign: TextAlign.center,
            ),
            if (action != null) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              FButton(
                key: const ValueKey('empty-state-view-action'),
                onPress: action!.onTap,
                child: Text(action!.label),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
