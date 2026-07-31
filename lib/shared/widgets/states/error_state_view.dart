import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/states/empty_state_view.dart';

/// A themed error-state card for async lists that failed to load.
///
/// Renders a centered alert icon + [title] + [body] stack inside an [FCard],
/// with an optional retry [action]. The retry callback is feature-supplied;
/// when [action] is `null`, no affordance is rendered.
class ErrorStateView extends StatelessWidget {
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
      key: const ValueKey('error-state-view'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
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
