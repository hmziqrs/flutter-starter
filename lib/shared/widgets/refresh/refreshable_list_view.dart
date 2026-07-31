import 'package:flutter/cupertino.dart';
import 'package:starter/infrastructure/platform/platform_capabilities.dart';
import 'package:starter/shared/widgets/refresh/app_refresh_indicator.dart';

enum RefreshIndicatorStyle {
  auto,

  material,

  cupertino,
}

class RefreshableListView<T> extends StatelessWidget {
  const RefreshableListView({
    required this.items,
    required this.itemBuilder,
    required this.keyOf,
    required this.onRefresh,
    this.style = RefreshIndicatorStyle.auto,
    this.padding,
    this.empty,
    this.separator,
    super.key,
  });

  final List<T> items;

  final Widget Function(BuildContext context, T item) itemBuilder;

  final String Function(T item) keyOf;

  final Future<void> Function() onRefresh;

  final RefreshIndicatorStyle style;

  final EdgeInsetsGeometry? padding;

  final Widget? empty;

  final Widget? separator;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _RefreshableEmpty(onRefresh: onRefresh, child: empty ?? const SizedBox.shrink());
    }

    final resolved = _resolveStyle(style);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final useCupertino = resolved == RefreshIndicatorStyle.cupertino && !reduceMotion;

    if (useCupertino) {
      return CustomScrollView(
        key: const ValueKey('refreshable-list-cupertino'),
        slivers: <Widget>[
          CupertinoSliverRefreshControl(onRefresh: onRefresh),
          _cupertinoSliver(),
        ],
      );
    }
    return AppRefreshIndicator(onRefresh: onRefresh, child: _materialList());
  }

  Widget _materialList() {
    if (separator != null) {
      return ListView.separated(
        key: const ValueKey('refreshable-list-material'),
        padding: padding,
        itemCount: items.length,
        itemBuilder: _itemBuilder,
        separatorBuilder: (_, _) => separator!,
      );
    }
    return ListView.builder(
      key: const ValueKey('refreshable-list-material'),
      padding: padding,
      itemCount: items.length,
      itemBuilder: _itemBuilder,
    );
  }

  Widget _cupertinoSliver() {
    if (separator == null) {
      return SliverList.builder(itemCount: items.length, itemBuilder: _itemBuilder);
    }
    final itemCount = items.length * 2 - 1;
    return SliverList.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index.isOdd) {
          return separator!;
        }
        final item = items[index ~/ 2];
        return KeyedSubtree(
          key: ValueKey('refreshable-${keyOf(item)}'),
          child: itemBuilder(context, item),
        );
      },
    );
  }

  Widget _itemBuilder(BuildContext context, int index) {
    final item = items[index];
    return KeyedSubtree(
      key: ValueKey('refreshable-${keyOf(item)}'),
      child: itemBuilder(context, item),
    );
  }

  RefreshIndicatorStyle _resolveStyle(RefreshIndicatorStyle requested) {
    if (requested != RefreshIndicatorStyle.auto) {
      return requested;
    }
    return PlatformCapabilities.current().isApplePlatform
        ? RefreshIndicatorStyle.cupertino
        : RefreshIndicatorStyle.material;
  }
}

class _RefreshableEmpty extends StatelessWidget {
  const _RefreshableEmpty({required this.onRefresh, required this.child});

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppRefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: <Widget>[child],
      ),
    );
  }
}
