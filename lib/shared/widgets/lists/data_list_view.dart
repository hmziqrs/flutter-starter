import 'package:flutter/widgets.dart';
import 'package:starter/shared/theme/app_spacing.dart';

/// A lazily-building, virtualized list primitive.
///
/// Only the visible items are built (`ListView.builder` / `ListView.separated`)
/// and each item keeps a stable `ValueKey` derived from [keyOf], so
/// widget/state identity survives edits and tests can target tiles by stable
/// id. Pads with the repo's spacing scale by default. The empty case renders a
/// feature-supplied [empty] placeholder (typically `EmptyStateView`).
class DataListView<T> extends StatelessWidget {
  /// Creates a [DataListView].
  const DataListView({
    required this.items,
    required this.itemBuilder,
    required this.keyOf,
    this.padding,
    this.empty,
    this.separator,
    this.shrinkWrap = false,
    this.physics,
    super.key,
  });

  /// The typed items to render lazily.
  final List<T> items;

  /// Builds the tile for a single [items] entry.
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// Returns the stable identifier for an item, used as the `ValueKey` seed.
  final String Function(T item) keyOf;

  /// List padding. Defaults to the repo's `AppSpacing.lg` content gutter.
  final EdgeInsetsGeometry? padding;

  /// Optional placeholder rendered when [items] is empty (typically
  /// `EmptyStateView`). When `null`, an empty `SizedBox` is rendered.
  final Widget? empty;

  /// Optional widget inserted between adjacent items.
  final Widget? separator;

  /// Whether the list sizes itself to its contents. Defaults to `false` so the
  /// list fills its parent and virtualizes.
  final bool shrinkWrap;

  /// Optional scroll physics override.
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return empty ?? const SizedBox.shrink();
    }
    final resolvedPadding =
        padding ??
        const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
        );
    if (separator != null) {
      return ListView.separated(
        key: const ValueKey('data-list-view'),
        padding: resolvedPadding,
        itemCount: items.length,
        shrinkWrap: shrinkWrap,
        physics: physics,
        separatorBuilder: (_, _) => separator!,
        itemBuilder: _itemBuilder,
      );
    }
    return ListView.builder(
      key: const ValueKey('data-list-view'),
      padding: resolvedPadding,
      itemCount: items.length,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemBuilder: _itemBuilder,
    );
  }

  Widget _itemBuilder(BuildContext context, int index) {
    final item = items[index];
    return KeyedSubtree(
      key: ValueKey('data-list-${keyOf(item)}'),
      child: itemBuilder(context, item),
    );
  }
}
