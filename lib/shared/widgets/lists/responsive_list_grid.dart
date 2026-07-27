import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/shared/adaptive/app_layout_class.dart';
import 'package:starter/shared/adaptive/app_layout_provider.dart';
import 'package:starter/shared/theme/app_spacing.dart';

/// Cross-axis counts per [AppLayoutClass] for [ResponsiveListGrid].
///
/// Defaults to the 1 / 2 / 3 column switch lifted out of `HomePage` so every
/// responsive grid in the starter uses one resolution rule. Provide an instance
/// with different counts to customize (e.g. a media gallery that stays 2-up on
/// compact layouts).
class ResponsiveGridColumns {
  const ResponsiveGridColumns({
    this.compact = 1,
    this.medium = 2,
    this.expanded = 3,
  });

  /// Cross-axis count under [AppLayoutClass.compact].
  final int compact;

  /// Cross-axis count under [AppLayoutClass.medium].
  final int medium;

  /// Cross-axis count under [AppLayoutClass.expanded].
  final int expanded;

  /// Resolves the count for [layoutClass].
  int resolve(AppLayoutClass layoutClass) {
    return switch (layoutClass) {
      AppLayoutClass.compact => compact,
      AppLayoutClass.medium => medium,
      AppLayoutClass.expanded => expanded,
    };
  }
}

/// A lazily-building grid whose cross-axis count tracks [AppLayoutClass].
///
/// Generalizes `HomePage`'s 1 / 2 / 3 column switch into a reusable primitive:
/// compact layouts render a single column (a vertical list), medium two,
/// expanded three — overridable via [crossAxisCounts]. Built on
/// `GridView.builder` so only visible cells materialize (virtualization), and
/// each cell keeps a stable `ValueKey` derived from [keyOf].
///
/// Pure presentational widget: typed items + builder, reads only the layout
/// provider + theme spacing, no state, no plugin, no side effects. The first
/// concrete consumer is `HomePage._StatusSection`; the designated deferred
/// consumers are pricing cards and search-result grids per the feature spec
/// (audit #3).
class ResponsiveListGrid<T> extends ConsumerWidget {
  /// Creates a [ResponsiveListGrid].
  const ResponsiveListGrid({
    required this.items,
    required this.itemBuilder,
    required this.keyOf,
    this.crossAxisCounts = const ResponsiveGridColumns(),
    this.mainAxisSpacing = AppSpacing.md,
    this.crossAxisSpacing = AppSpacing.md,
    this.childAspectRatio = 1.0,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    super.key,
  });

  /// The typed items to render lazily.
  final List<T> items;

  /// Builds the cell for a single [items] entry.
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// Returns the stable identifier for an item, used as the `ValueKey` seed.
  final String Function(T item) keyOf;

  /// Per-layout cross-axis counts. Defaults to 1 / 2 / 3.
  final ResponsiveGridColumns crossAxisCounts;

  /// Spacing between rows.
  final double mainAxisSpacing;

  /// Spacing between columns.
  final double crossAxisSpacing;

  /// Cell aspect ratio (width / height).
  final double childAspectRatio;

  /// Grid padding. Defaults to the repo's `AppSpacing.lg` content gutter.
  final EdgeInsetsGeometry? padding;

  /// Whether the grid sizes itself to its contents.
  final bool shrinkWrap;

  /// Optional scroll physics override.
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layoutClass = ref.watch(appLayoutClassProvider);
    final crossAxisCount = crossAxisCounts.resolve(layoutClass);
    final resolvedPadding =
        padding ??
        const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
        );
    return GridView.builder(
      key: ValueKey('responsive-grid-$crossAxisCount'),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      padding: resolvedPadding,
      itemCount: items.length,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemBuilder: (context, index) {
        final item = items[index];
        return KeyedSubtree(
          key: ValueKey('responsive-grid-${keyOf(item)}'),
          child: itemBuilder(context, item),
        );
      },
    );
  }
}
