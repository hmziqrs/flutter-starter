import 'package:flutter/widgets.dart';
import 'package:starter/shared/theme/app_spacing.dart';

class DataListView<T> extends StatelessWidget {
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

  final List<T> items;

  final Widget Function(BuildContext context, T item) itemBuilder;

  final String Function(T item) keyOf;

  final EdgeInsetsGeometry? padding;

  final Widget? empty;

  final Widget? separator;

  final bool shrinkWrap;

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
