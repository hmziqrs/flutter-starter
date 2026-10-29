import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/widgets/brand/app_ring_marker.dart';

/// Before and after (BRAND.md s8, before-after.svelte): the manual way
/// struck through, then what the tool does instead.
///
/// The app draws the two sides as thin outline columns: the before side
/// strikes its items through in muted words (the svelte `<s>` at
/// decoration-muted-foreground/70), the after side marks each item with the
/// filled primary ring. Only colors and the strike change — nothing moves.
/// They sit side by side from 600dp and stack below it.
class AppBeforeAfter extends StatelessWidget {
  const AppBeforeAfter({
    required this.beforeLabel,
    required this.afterLabel,
    required this.beforeItems,
    required this.afterItems,
    super.key,
  });

  /// The manual way, e.g. "By hand".
  final String beforeLabel;

  /// What replaces it, e.g. "With this tool".
  final String afterLabel;

  final List<String> beforeItems;

  final List<String> afterItems;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final before = _Column(
      label: beforeLabel,
      struckThrough: true,
      items: beforeItems,
      borderColor: theme.colors.border,
      labelColor: theme.colors.mutedForeground,
    );
    final after = _Column(
      label: afterLabel,
      struckThrough: false,
      items: afterItems,
      borderColor: theme.colors.border,
      labelColor: theme.colors.foreground,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 600) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: before),
              const SizedBox(width: 12),
              Expanded(child: after),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[before, const SizedBox(height: 12), after],
        );
      },
    );
  }
}

class _Column extends StatelessWidget {
  const _Column({
    required this.label,
    required this.struckThrough,
    required this.items,
    required this.borderColor,
    required this.labelColor,
  });

  final String label;

  final bool struckThrough;

  final List<String> items;

  final Color borderColor;

  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: Colors.transparent,
        shape: RoundedSuperellipseBorder(
          side: BorderSide(color: borderColor, width: theme.style.borderWidth),
          borderRadius: theme.style.borderRadius.lg,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: theme.typography.body.sm.copyWith(
              color: labelColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < items.length; index++) ...<Widget>[
            if (index > 0) const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // The after side carries the filled primary ring
                // (before-after.svelte: Marker filled text-primary); the
                // struck side runs bare, like the svelte's plain `<s>`.
                if (!struckThrough) ...<Widget>[
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: 5.5),
                    child: AppRingMarker(filled: true, color: theme.colors.primary),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    items[index],
                    style: theme.typography.body.sm.copyWith(
                      color: struckThrough ? theme.colors.mutedForeground : theme.colors.foreground,
                      decoration: struckThrough ? TextDecoration.lineThrough : TextDecoration.none,
                      decorationColor: theme.colors.mutedForeground.withValues(alpha: 0.70),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
