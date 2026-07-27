import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/app_spacing.dart';

/// An optional call-to-action attached to a state-view widget.
///
/// The `label` is rendered on the action affordance and `onTap` fires when the
/// affordance is invoked. The action is always feature-supplied: the state
/// views never substitute a default (no-op) callback. A feature with no backend
/// wires `onTap` to surface `common.notConnected` honestly — it must never claim
/// success for an action that has no backend (audit checklist #13).
typedef StateViewAction = ({String label, VoidCallback onTap});

/// A themed empty-state card for async lists that have nothing to show yet.
///
/// Renders a centered icon + [title] + [body] stack inside an [FCard], with an
/// optional [action] affordance. The stack is fully centered, so it is
/// direction-neutral — Arabic glyph spacing and icon placement need no extra
/// mirroring (audit checklist #6).
///
/// This is a pure presentational widget: it takes typed [title] / [body]
/// strings and reads only `BuildContext.theme`, so it owns no state, calls no
/// plugin, and performs no side effects. The first concrete consumer is
/// `HomePage._RecentActivity`; the designated deferred consumers are
/// search-results (search-pagination) and cached lists (offline-cache) per the
/// feature spec (audit checklist #3).
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
      // Stable identity for widget/integration tests and gallery previews.
      key: const ValueKey('empty-state-view'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Semantics(
              label: title,
              image: true,
              child: Icon(icon, size: 32),
            ),
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
