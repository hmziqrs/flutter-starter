import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/shared/state/paged_state.dart';

abstract base class PagedStateNotifierBase<T> extends Notifier<PagedState<T>> {
  PageFetcher<T> get fetcher;

  @override
  PagedState<T> build() => PagedState<T>();

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

  void reset() {
    state = PagedState<T>();
  }
}

PageFetcher<T> noopPageFetcher<T>() {
  return (_) async => throw PagedFetchException.notConnected();
}
