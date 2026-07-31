import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/shared/adaptive/app_layout_class.dart';
import 'package:starter/shared/adaptive/app_layout_provider.dart';
import 'package:starter/shared/theme/app_spacing.dart';

class ResponsiveGridColumns {
  const ResponsiveGridColumns({
    this.compact = 1,
    this.medium = 2,
    this.expanded = 3,
  });

  final int compact;

  final int medium;

  final int expanded;

  int resolve(AppLayoutClass layoutClass) {
    return switch (layoutClass) {
      AppLayoutClass.compact => compact,
      AppLayoutClass.medium => medium,
      AppLayoutClass.expanded => expanded,
    };
  }
}

class ResponsiveListGrid<T> extends ConsumerWidget {
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

  final List<T> items;

  final Widget Function(BuildContext context, T item) itemBuilder;

  final String Function(T item) keyOf;

  final ResponsiveGridColumns crossAxisCounts;

  final double mainAxisSpacing;

  final double crossAxisSpacing;

  final double childAspectRatio;

  final EdgeInsetsGeometry? padding;

  final bool shrinkWrap;

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
