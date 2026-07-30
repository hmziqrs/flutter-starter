import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/shared/state/paged_state.dart';

/// Riverpod [Notifier] base that drives a [PagedState] over an injected
/// [PageFetcher] port.
///
/// Subclasses return their fetcher from [fetcher] (a feature with a backend
/// wires a real source; the no-backend default is [noopPageFetcher]).
/// `refresh()` reloads page one, `loadNext()` appends the next page (or loads
/// page one from `idle`), and `reset()` returns to the idle seed. Each subclass
/// is its own [NotifierProvider], so the fetcher doubles as the injection key.
abstract base class PagedStateNotifierBase<T> extends Notifier<PagedState<T>> {
  /// The typed port this notifier drives.
  PageFetcher<T> get fetcher;

  @override
  PagedState<T> build() => PagedState<T>();

  /// Reloads page one, replacing the accumulated items.
  Future<void> refresh() async {
    state = PagedState<T>(status: PagedStateStatus.loading);
    try {
      final result = await fetcher(null);
      state = PagedState<T>(
        items: List<T>.unmodifiable(result.items),
        status: PagedStateStatus.ready,
        cursor: result.nextCursor,
        hasMore: result.nextCursor != null,
      );
    } on Object catch (error) {
      state = state.copyWith(status: PagedStateStatus.error, error: error);
    }
  }

  /// Appends the next page. A no-op while a fetch is already in flight or once
  /// the source has reported no more pages. Used by `PagedListView` near
  /// scroll end.
  Future<void> loadNext() async {
    if (state.isLoading || state.isLoadingNext) return;
    if (!state.hasMore) return;
    final cursor = state.cursor;
    state = state.copyWith(status: PagedStateStatus.loadingNext);
    try {
      final result = await fetcher(cursor);
      final combined = <T>[...state.items, ...result.items];
      state = PagedState<T>(
        items: List<T>.unmodifiable(combined),
        status: PagedStateStatus.ready,
        cursor: result.nextCursor,
        hasMore: result.nextCursor != null,
      );
    } on Object catch (error) {
      state = state.copyWith(status: PagedStateStatus.error, error: error);
    }
  }

  /// Returns the notifier to the idle seed, discarding accumulated items and
  /// the continuation cursor.
  void reset() {
    state = PagedState<T>();
  }
}

/// The default [PageFetcher] for paged surfaces with no backing store: every
/// call throws [PagedFetchException.notConnected] rather than synthesizing a
/// page.
PageFetcher<T> noopPageFetcher<T>() {
  return (_) async => throw PagedFetchException.notConnected();
}
