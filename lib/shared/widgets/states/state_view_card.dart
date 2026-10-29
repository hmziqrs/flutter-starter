import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/brand/app_icon_tile.dart';

typedef StateViewAction = ({String label, VoidCallback onTap});

/// How a state view is accented (APP-BLOCKS states): neutral keeps the
/// brand's default — an outline tile with the icon in primary, the tone-less
/// IconTile of empty-state.svelte; destructive carries the error accent
/// (error-state.svelte's `text-destructive` for the failed kind).
enum StateViewTone { neutral, destructive }

/// An app state rendered the brand way (APP-BLOCKS.md EmptyState/ErrorState,
/// DataState "No box"): an unboxed centered column — no border, no fill —
/// of the icon tile, the copy and the one way out.
///
/// The column centers in the content area (`flex-1 items-center
/// justify-center`) and scrolls when the copy outgrows it, so it works in a
/// full page, a section, or a short bounded slot.
class StateViewCard extends StatelessWidget {
  const StateViewCard({
    required this.keyPrefix,
    required this.icon,
    required this.title,
    required this.body,
    this.action,
    this.tone = StateViewTone.neutral,
    this.actionVariant,
    super.key,
  });

  final String keyPrefix;

  final IconData icon;

  final String title;

  final String body;

  final StateViewAction? action;

  final StateViewTone tone;

  /// Which button [action] draws. Null follows the tone: the destructive
  /// retry and the first-use empty action are the solid default variant
  /// (APP-BLOCKS ErrorState "Try again", EmptyState "for a first run, the
  /// one action that starts things"); link-style clear/search actions pass
  /// [FButtonVariant.outline].
  final FButtonVariant? actionVariant;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    // Null leaves the AppIconTile default: primary icon on the outline tile.
    final iconTone = switch (tone) {
      StateViewTone.neutral => null,
      StateViewTone.destructive => colors.destructive,
    };
    final resolvedActionVariant =
        actionVariant ??
        switch (tone) {
          StateViewTone.neutral || StateViewTone.destructive => FButtonVariant.primary,
        };
    // The state title's `text-lg font-medium tracking-tight` and the
    // description's `text-sm text-muted-foreground` (empty-state.svelte).
    final titleStyle = theme.typography.body.lg.copyWith(
      color: colors.foreground,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.025 * (theme.typography.body.lg.fontSize ?? 18),
    );
    final bodyStyle = theme.typography.body.sm.copyWith(color: colors.mutedForeground);

    // empty-state.svelte's column: the tile, then a max-w-sm column with
    // gap-2 carrying the title, the description and the `mt-2` action.
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AppIconTile(icon: icon, iconColor: iconTone),
        // gap-4 between the tile and the text block.
        SizedBox(height: context.spacing.lg),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 384),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                title,
                key: ValueKey('$keyPrefix-title'),
                style: titleStyle,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: context.spacing.sm),
              Text(
                body,
                key: ValueKey('$keyPrefix-body'),
                style: bodyStyle,
                textAlign: TextAlign.center,
              ),
              if (action != null) ...<Widget>[
                SizedBox(height: context.spacing.sm),
                FButton(
                  key: ValueKey('$keyPrefix-action'),
                  onPress: action!.onTap,
                  variant: resolvedActionVariant,
                  child: Text(action!.label),
                ),
              ],
            ],
          ),
        ),
      ],
    );

    return LayoutBuilder(
      key: ValueKey(keyPrefix),
      builder: (context, constraints) {
        // The brand column fills and centers in the content area
        // (`flex-1 justify-center`); in an unbounded parent (another
        // scroller) it falls back to hugging its own height.
        final minHeight = constraints.hasBoundedHeight ? constraints.maxHeight : 0.0;
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Center(
              // py-16 (empty-state.svelte's page size).
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 64),
                child: column,
              ),
            ),
          ),
        );
      },
    );
  }
}
