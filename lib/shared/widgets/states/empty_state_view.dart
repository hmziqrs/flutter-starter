import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/app_spacing.dart';

/// An optional call-to-action attached to a state-view widget. `label` is
/// rendered on the action affordance and `onTap` fires when invoked. Always
/// feature-supplied — state views never substitute a default callback.
typedef StateViewAction = ({String label, VoidCallback onTap});

/// A themed empty-state card for async lists that have nothing to show yet.
///
/// Renders a centered icon + [title] + [body] stack inside an [FCard], with an
/// optional [action] affordance.
class EmptyStateView extends StatelessWidget {
  /// Creates an [EmptyStateView].
  const EmptyStateView({
    required this.title,
    required this.body,
    this.icon = FLucideIcons.inbox,
    this.action,
    super.key,
  });

  /// Localized title copy (e.g. `states.emptyTitle`).
  final String title;

  /// Localized body copy (e.g. `states.emptyBody`).
  final String body;

  /// Leading icon. Defaults to a neutral inbox glyph.
  final IconData icon;

  /// Optional call-to-action. When `null`, no affordance is rendered.
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
