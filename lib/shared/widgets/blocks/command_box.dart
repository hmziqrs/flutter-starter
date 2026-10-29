import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// One row of an [AppCommandBox]: an icon and what to do, in order.
class AppCommandStep {
  const AppCommandStep({required this.label, required this.icon, this.semanticLabel});

  /// What the step does. Sentence case comes from the caller.
  final String label;

  /// The step's icon; `FLucideIcons` stay inside the app's own set.
  final IconData icon;

  /// What screen readers call the icon when it stands alone; defaults to the
  /// label.
  final String? semanticLabel;
}

/// The compact step list (the command kit's box variant): a tight rounded
/// border, and each step as an icon row — the recipe for a short fixed
/// sequence, where `AppCommandBar` carries the single command to copy.
///
/// Steps are displayed, not tapped: the box narrates, the page's own
/// controls act.
class AppCommandBox extends StatelessWidget {
  const AppCommandBox({required this.steps, super.key});

  final List<AppCommandStep> steps;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: ShapeDecoration(
        color: Colors.transparent,
        shape: RoundedSuperellipseBorder(
          side: BorderSide(color: theme.colors.border, width: theme.style.borderWidth),
          borderRadius: theme.style.borderRadius.md,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (var index = 0; index < steps.length; index++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: <Widget>[
                  Icon(
                    steps[index].icon,
                    size: 16,
                    color: theme.colors.mutedForeground,
                    semanticLabel: steps[index].semanticLabel,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      steps[index].label,
                      style: theme.typography.body.sm.copyWith(color: theme.colors.foreground),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
