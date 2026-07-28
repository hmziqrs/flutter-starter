import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/shared/state/paged_state.dart';

/// Hand-written Riverpod [Notifier] base that drives a [PagedState] over an
/// injected [PageFetcher] port.
///
/// Subclasses supply the typed fetcher (the C2 port — a feature with a backend
/// wires a real source; the no-backend default is [noopPageFetcher]). The base
/// owns the state machine: `refresh()` reloads page one (clears + loads),
/// `loadNext()` appends the next page (or loads page one when the state is
/// still `idle`), and `reset()` returns to the idle seed. Every fetch wraps the
/// port in `try { ... } on Object` so a thrown [PagedFetchException] (or any
/// other failure) lands on [PagedState.error] as a typed `Object?` — never
/// `dynamic`, and never a faked populated page (audit #7, #13).
///
/// The "family keyed by fetcher" from the feature spec is realized as one
/// feature-local [NotifierProvider] subclass per paged surface: each subclass
/// returns its fetcher from [fetcher] (the fetcher IS the injection key), so
/// the cache entry is named, typed, and overridable at the composition root —
/// mirroring the `SettingsStore` / `OtpRepository` discipline. Riverpod
/// `.family` over a function-typed arg would break cache equality (closures are
/// not `==` by value), so a codegen-free family is rejected in favor of the
/// subclass-per-source shape.
///
/// The first concrete consumer is the search feature
/// (`SearchResultsController`); the designated deferred consumers are
/// offline-cache (cached paged list) and any future server-paged surface. That
/// clears the shared-state-helper bar (C3: ≥1 consumer + reuse intent); the
/// ≥3-consumer rule is for widgets/forms, not state helpers.
abstract base class PagedStateNotifierBase<T> extends Notifier<PagedState<T>> {
  /// The typed port this notifier drives. Overridden by a feature's concrete
  /// subclass to return a real fetcher (backend wired) or the no-backend
  /// [noopPageFetcher] (default surfaces `common.notConnected`).
  PageFetcher<T> get fetcher;

  @override
  PagedState<T> build() => PagedState<T>();

  /// Reloads page one, replacing the accumulated items. Drives the
  /// `idle|error|ready → loading → ready|error` transition. Used on initial
  /// mount, query change, and pull-to-refresh. Clears [PagedState.items] and
  /// [PagedState.cursor] up front so the list shows the first-page loading
  /// state rather than stale content.
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
  /// the source has reported no more pages. From the `idle` seed this performs
  /// the first load (transitioning `idle → loadingNext → ready`); from `ready`
  /// it appends (transitioning `ready → loadingNext → ready`); from `error` it
  /// retries the failed page. Used by `PagedListView` near scroll end.
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
  /// the continuation cursor. Used when the consumer leaves the paged surface
  /// so a return does not show stale content.
  void reset() {
    state = PagedState<T>();
  }
}

/// The honest no-backend [PageFetcher]. Every call throws
/// [PagedFetchException.notConnected] — never a synthesized populated page
/// (C2: the default surfaces `common.notConnected`; audit #13). A consumer
/// wires a real fetcher only when a source is configured; until then this is
/// the production default for paged surfaces with no backing store.
PageFetcher<T> noopPageFetcher<T>() {
  return (_) async => throw PagedFetchException.notConnected();
}
