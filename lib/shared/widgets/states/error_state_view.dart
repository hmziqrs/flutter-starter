import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/states/empty_state_view.dart';

/// A themed error-state card for async lists that failed to load.
///
/// Renders a centered alert icon + [title] + [body] stack inside an [FCard],
/// with an optional retry [action]. The stack is fully centered, so it is
/// direction-neutral — Arabic glyph spacing and icon placement need no extra
/// mirroring (audit checklist #6).
///
/// The retry callback is feature-supplied via [action]; the view never supplies
/// a default (no-op) `onTap`. When [action] is `null`, no affordance is
/// rendered — a feature with no backend wires [StateViewAction] `onTap` to
/// surface `common.notConnected` honestly and never fakes success (audit
/// checklist #13, feature spec "No silent retry"). The action label is
/// feature-supplied too; call sites use `common.retry`.
///
/// Pure presentational widget: typed [title] / [body] strings, reads only
/// `BuildContext.theme`, no state, no plugin calls, no side effects.
class ErrorStateView extends StatelessWidget {
  /// Creates an [ErrorStateView].
  const ErrorStateView({
    required this.title,
    required this.body,
    this.icon = FLucideIcons.circleAlert,
    this.action,
    super.key,
  });

  /// Localized title copy (e.g. `states.errorTitle`).
  final String title;

  /// Localized body copy (e.g. `states.errorBody`).
  final String body;

  /// Leading alert icon. Defaults to a circle-alert glyph.
  final IconData icon;

  /// Optional retry action. When `null`, no affordance is rendered.
  final StateViewAction? action;

  @override
  Widget build(BuildContext context) {
    return FCard(
      // Stable identity for widget/integration tests and gallery previews.
      key: const ValueKey('error-state-view'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Decorative: the adjacent title Text carries the name. An explicit
            // label here would duplicate the title in the AT announcement.
            Icon(icon, size: 32),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              key: const ValueKey('error-state-view-title'),
              style: context.theme.cardStyle.titleTextStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              body,
              key: const ValueKey('error-state-view-body'),
              style: context.theme.cardStyle.subtitleTextStyle,
              textAlign: TextAlign.center,
            ),
            if (action != null) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              FButton(
                key: const ValueKey('error-state-view-action'),
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
