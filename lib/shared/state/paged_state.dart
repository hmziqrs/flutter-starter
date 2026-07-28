import 'package:flutter/foundation.dart';

/// Lifecycle status of a [PagedState]. Follows the repo's smallest-vocabulary
/// convention (idle / loading / ready / loadingNext / error):
///
/// - `idle` — the notifier has been built but no page has been requested yet.
/// - `loading` — the first page is in flight (refresh / initial load).
/// - `ready` — at least one page is loaded; a subsequent page may be available.
/// - `loadingNext` — a subsequent page is in flight (scroll-triggered loadNext).
/// - `error` — the last fetch failed; the captured exception is on
///   [PagedState.error].
enum PagedStateStatus { idle, loading, ready, loadingNext, error }

/// The reason a [PageFetcher] failed. Exhaustive so consumers can switch over
/// it without a default (audit #7).
enum PagedFetchFailureKind { notConnected }

/// Typed exception raised by a [PageFetcher]. Mirrors the
/// `SettingsStore` / `OtpRepository` discipline: a single typed exception with
/// a `.notConnected` factory so the honest no-backend state is expressible
/// without faking a populated page (audit #13).
final class PagedFetchException implements Exception {
  const PagedFetchException._(this.kind);

  /// The no-backend default: the fetcher has no source wired and must surface
  /// `common.notConnected` rather than synthesizing a page. The hand-rolled
  /// `noopPageFetcher` throws this on every call.
  factory PagedFetchException.notConnected() =>
      const PagedFetchException._(PagedFetchFailureKind.notConnected);

  final PagedFetchFailureKind kind;

  @override
  String toString() => 'PagedFetchException: ${kind.name}';
}

/// The result of a single [PageFetcher] call: one page of typed items plus the
/// opaque cursor to request the next page (or `null` when there are no more).
///
/// The cursor is an `int` offset — the item index the next page should start at
/// (`null` means "no next page"). The feature spec's `PageFetcher<T>` wrote the
/// cursor as `T?`; a cursor cannot be the item type, so the strict realization
/// is a typed `int?` offset (no `dynamic`/`Object` escape hatch, audit #7).
@immutable
final class PagedResult<T> {
  /// Creates a [PagedResult].
  const PagedResult({required this.items, this.nextCursor});

  /// The typed items in this page. The notifier appends these to the running
  /// [PagedState.items] list.
  final List<T> items;

  /// The offset the next page should start at, or `null` when this was the last
  /// page. The notifier stores this on [PagedState.cursor] and uses it to gate
  /// `loadNext` (no next page — no further fetch).
  final int? nextCursor;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PagedResult<T> &&
            _listEquals(items, other.items) &&
            nextCursor == other.nextCursor;
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(items), nextCursor);

  @override
  String toString() => 'PagedResult(items: ${items.length}, nextCursor: $nextCursor)';
}

/// The typed port a `PagedStateNotifierBase` injects. A feature with a backend
/// supplies a fetcher that hits its source; the no-backend default is the
/// hand-rolled `noopPageFetcher`, which throws [PagedFetchException.notConnected]
/// and never synthesizes a page (C2 — port + Noop default; audit #13).
///
/// The cursor is `null` for the first page and the [PagedResult.nextCursor]
/// returned by the previous page thereafter.
typedef PageFetcher<T> = Future<PagedResult<T>> Function(int? cursor);

/// Immutable paged-list state. Generic over the item type `T`; the cursor is a
/// typed `int?` offset. Owned by `PagedStateNotifierBase`; consumed by widgets
/// (`PagedListView`) via `ref.watch`.
///
/// The state is value-equal (deep `==` over [items]) so `ref.watch` rebuilds
/// only on a real content change, not on a notifier identity change.
@immutable
final class PagedState<T> {
  /// Creates a [PagedState]. Defaults to the `idle` first-build state.
  const PagedState({
    this.items = const [],
    this.status = PagedStateStatus.idle,
    this.cursor,
    this.hasMore = true,
    this.error,
  });

  /// The typed items accumulated across all loaded pages. Unmodified by the
  /// state object itself; the notifier appends each page's [PagedResult.items].
  final List<T> items;

  /// The current lifecycle status (see [PagedStateStatus]).
  final PagedStateStatus status;

  /// The offset the next page should start at, or `null` when the last page
  /// loaded was the final one. Drives `loadNext`'s continuation.
  final int? cursor;

  /// Whether another page may be available. Flipped to `false` once a fetcher
  /// returns a `null` [PagedResult.nextCursor]; `loadNext` is a no-op while this
  /// is false. Independent of [status] so a `ready`+`!hasMore` state correctly
  /// disables the scroll-triggered fetch.
  final bool hasMore;

  /// The exception captured by the last failed fetch, or `null`. Present only
  /// when [status] is [PagedStateStatus.error]. Typed as `Object?` (the captured
  /// throw) — never `dynamic`.
  final Object? error;

  /// `true` while a subsequent page is in flight. Convenience for the list
  /// footer spinner.
  bool get isLoadingNext => status == PagedStateStatus.loadingNext;

  /// `true` while the first page is in flight (initial load / refresh).
  bool get isLoading => status == PagedStateStatus.loading;

  /// `true` when the last fetch failed.
  bool get hasError => status == PagedStateStatus.error;

  /// `true` when the first page has resolved to zero items (the empty case).
  /// Only meaningful once [status] is `ready`; an `idle`/`loading` state is not
  /// "empty" — it is unresolved.
  bool get isEmpty => status == PagedStateStatus.ready && items.isEmpty && error == null;

  PagedState<T> copyWith({
    List<T>? items,
    PagedStateStatus? status,
    int? cursor,
    bool? hasMore,
    Object? error,
    bool clearCursor = false,
    bool clearError = false,
  }) {
    return PagedState<T>(
      items: items ?? this.items,
      status: status ?? this.status,
      cursor: clearCursor ? null : (cursor ?? this.cursor),
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PagedState<T> &&
            _listEquals(items, other.items) &&
            status == other.status &&
            cursor == other.cursor &&
            hasMore == other.hasMore &&
            error == other.error;
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(items), status, cursor, hasMore, error);

  @override
  String toString() =>
      'PagedState(status: $status, items: ${items.length}, cursor: $cursor, '
      'hasMore: $hasMore, error: $error)';
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i += 1) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
