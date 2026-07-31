import 'package:flutter/cupertino.dart';
import 'package:starter/infrastructure/platform/platform_capabilities.dart';
import 'package:starter/shared/widgets/refresh/app_refresh_indicator.dart';

/// Selects the native pull-to-refresh affordance for [RefreshableListView].
enum RefreshIndicatorStyle {
  /// Cupertino sliver control on Apple platforms, Material indicator elsewhere.
  auto,

  /// Always Flutter's Material `RefreshIndicator` (themed by [AppRefreshIndicator]).
  material,

  /// Always Flutter's `CupertinoSliverRefreshControl`.
  cupertino,
}

/// A lazily-building list with a pull-to-refresh affordance.
///
/// Composes [AppRefreshIndicator] (Material) or a
/// `CupertinoSliverRefreshControl` (Apple) over a `ListView.builder` /
/// `SliverList.builder`, so only the visible items are built and each item
/// keeps a stable `ValueKey` derived from [keyOf].
///
/// The `auto` style resolves Cupertino on Apple platforms (via
/// [PlatformCapabilities.isApplePlatform]) and Material elsewhere. Under
/// `MediaQuery.disableAnimationsOf` the Cupertino branch falls back to the
/// Material indicator, since the Cupertino spinner cannot be made transparent
/// without dropping the control.
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

  /// The typed items to render lazily.
  final List<T> items;

  /// Builds the tile for a single [items] entry.
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// Returns the stable identifier for an item, used as the `ValueKey` seed.
  final String Function(T item) keyOf;

  /// Feature-supplied refresh callback. Drives the pull-to-refresh affordance.
  final Future<void> Function() onRefresh;

  /// Which native affordance to mount. Defaults to platform-appropriate.
  final RefreshIndicatorStyle style;

  /// List padding. `null` leaves the platform default.
  final EdgeInsetsGeometry? padding;

  /// Optional placeholder rendered when [items] is empty (typically
  /// `EmptyStateView`). Pull-to-refresh stays active around it.
  final Widget? empty;

  /// Optional widget inserted between adjacent items.
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

/// Wraps the empty placeholder in an always-scrollable list so the
/// [AppRefreshIndicator] still observes the pull gesture on an empty data set.
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
