import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/state/paged_state.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/states/empty_state_view.dart';
import 'package:starter/shared/widgets/states/error_state_view.dart';
import 'package:starter/shared/widgets/states/loading_state_view.dart';

/// When the viewport is within this many pixels of the bottom and the notifier
/// still has more pages, [PagedListView.onLoadNext] fires.
const double _loadNextThresholdPixels = 240;

/// A lazily-building, virtualized paged list driven by a [PagedState].
///
/// Sits next to `DataListView` under `lib/shared/widgets/lists/` and reuses its
/// virtualization shape — a `ListView.builder` whose tiles keep a stable
/// `ValueKey` derived from [keyOf] so widget/state identity survives page
/// appends. `DataListView` exposes no scroll-controller / trailing-footer slot,
/// so the paged variant builds its own builder: a `NotificationListener` fires
/// [onLoadNext] when the viewport approaches the end and the state reports more
/// pages available (scroll-triggered pagination is never animation-gated, audit
/// #5), and a trailing `_LoadNextFooter` is appended while a subsequent page is
/// in flight.
///
/// State mapping (the view never fakes content, audit #13):
/// - `loading` (first page / refresh) → centered [LoadingStateView].
/// - `error` → [ErrorStateView] with a retry action wired to [onRefresh] (a
///   failed first page) or [onLoadNext] (a failed subsequent page). The body
///   defaults to `common.notConnected` so a no-backend fetcher surfaces the
///   honest unavailable state.
/// - `ready` + empty → [EmptyStateView] (feature-supplied title/body).
/// - `ready` + items → the builder; a `_LoadNextFooter` is appended while
///   `loadingNext` is true.
///
/// Pure presentational composition: typed [state] + builders + callbacks, reads
/// only `BuildContext.theme` + `context.t`. No plugin, no side effect beyond
/// the scroll-triggered callback. The first concrete consumer is `SearchPage`;
/// the designated deferred consumers are offline-cache (cached paged list) and
/// any future server-paged surface (audit #3).
class PagedListView<T> extends StatelessWidget {
  /// Creates a [PagedListView].
  const PagedListView({
    required this.state,
    required this.itemBuilder,
    required this.keyOf,
    required this.onLoadNext,
    required this.onRefresh,
    required this.emptyTitle,
    required this.emptyBody,
    required this.errorTitle,
    this.errorBody,
    this.padding,
    this.separator,
    super.key,
  });

  /// The paged state to render. Usually `ref.watch(pagedControllerProvider)`.
  final PagedState<T> state;

  /// Builds the tile for a single item.
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// Returns the stable identifier for an item, used as the `ValueKey` seed.
  final String Function(T item) keyOf;

  /// Fired when the viewport approaches the end and [PagedState.hasMore] is
  /// true. The consumer forwards this to its paged notifier's `loadNext()`.
  final Future<void> Function() onLoadNext;

  /// Fired when the user pulls to refresh (or retries a failed first page). The
  /// consumer forwards this to its paged notifier's `refresh()`.
  final Future<void> Function() onRefresh;

  /// Localized empty-state title (e.g. `search.emptyTitle`).
  final String emptyTitle;

  /// Localized empty-state body (e.g. `search.emptyBody`).
  final String emptyBody;

  /// Localized error-state title (e.g. `search.errorTitle`).
  final String errorTitle;

  /// Optional localized error-state body. Defaults to `common.notConnected` —
  /// the view surfaces the honest unavailable state and never invents a cause.
  final String? errorBody;

  /// List padding. Defaults to the repo's `AppSpacing.lg` content gutter
  /// (mirrors `DataListView`).
  final EdgeInsetsGeometry? padding;

  /// Optional widget inserted between adjacent items.
  final Widget? separator;

  @override
  Widget build(BuildContext context) {
    final state = this.state;
    if (state.isLoading) {
      return LoadingStateView(title: context.t.states.loadingTitle);
    }
    if (state.hasError) {
      return ErrorStateView(
        title: errorTitle,
        body: errorBody ?? context.t.common.notConnected,
        action: (
          label: context.t.common.retry,
          // A failed first page (no items yet) retries the full refresh; a
          // failed subsequent page retries loadNext to resume appending.
          onTap: state.items.isEmpty ? () => unawaited(onRefresh()) : () => unawaited(onLoadNext()),
        ),
      );
    }
    if (state.isEmpty) {
      return EmptyStateView(title: emptyTitle, body: emptyBody);
    }
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: ListView.builder(
        key: const ValueKey('paged-list-view'),
        padding:
            padding ??
            const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
        // One extra slot for the loadingNext footer when a subsequent page is
        // in flight; otherwise the count is exactly the item count.
        itemCount: state.items.length + (state.isLoadingNext ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.items.length) {
            return const _LoadNextFooter();
          }
          final item = state.items[index];
          final tile = itemBuilder(context, item);
          if (separator case final divider?) {
            return Column(
              children: [
                KeyedSubtree(
                  key: ValueKey('paged-${keyOf(item)}'),
                  child: tile,
                ),
                divider,
              ],
            );
          }
          return KeyedSubtree(
            key: ValueKey('paged-${keyOf(item)}'),
            child: tile,
          );
        },
      ),
    );
  }

  /// Fires [onLoadNext] once the viewport nears the end. The notifier guards
  /// against concurrent loads and no-more-pages, so a redundant call is a cheap
  /// no-op — no debouncing is needed here.
  bool _onScroll(ScrollNotification notification) {
    if (!state.hasMore || state.isLoadingNext || state.isLoading) {
      return false;
    }
    if (notification is! ScrollUpdateNotification) {
      return false;
    }
    final metrics = notification.metrics;
    if (metrics.pixels >= metrics.maxScrollExtent - _loadNextThresholdPixels) {
      unawaited(onLoadNext());
    }
    return false;
  }
}

/// A small centered spinner rendered while a subsequent page is in flight. The
/// decorative [FProgress] is the only motion here; the list itself stays
/// non-animated (audit #5), and the `loadingNext` flag flips without an
/// animation transition gate.
class _LoadNextFooter extends StatelessWidget {
  const _LoadNextFooter();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Center(child: FProgress()),
    );
  }
}
