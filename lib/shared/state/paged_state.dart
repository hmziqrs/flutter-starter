import 'package:freezed_annotation/freezed_annotation.dart';

part 'paged_state.freezed.dart';

/// Lifecycle status of a [PagedState].
enum PagedStateStatus { idle, loading, ready, loadingNext, error }

/// The reason a [PageFetcher] failed.
enum PagedFetchFailureKind { notConnected }

/// Typed exception raised by a [PageFetcher].
final class PagedFetchException implements Exception {
  const PagedFetchException._(this.kind);

  /// The no-backend default: no source is wired, so `common.notConnected`
  /// surfaces instead of a synthesized page.
  factory PagedFetchException.notConnected() =>
      const PagedFetchException._(PagedFetchFailureKind.notConnected);

  final PagedFetchFailureKind kind;

  @override
  String toString() => 'PagedFetchException: ${kind.name}';
}

/// The result of a single [PageFetcher] call: one page of typed items plus the
/// cursor to request the next page (`null` when there are no more).
@freezed
class PagedResult<T> with _$PagedResult<T> {
  const PagedResult({required this.items, this.nextCursor});

  /// The typed items in this page.
  @override
  final List<T> items;

  /// The offset the next page should start at, or `null` when this was the
  /// last page.
  @override
  final int? nextCursor;

  @override
  String toString() => 'PagedResult(items: ${items.length}, nextCursor: $nextCursor)';
}

/// The typed port a `PagedStateNotifierBase` injects. The cursor is `null` for
/// the first page and the previous page's [PagedResult.nextCursor] thereafter.
typedef PageFetcher<T> = Future<PagedResult<T>> Function(int? cursor);

/// Immutable paged-list state, owned by `PagedStateNotifierBase` and consumed
/// by widgets (`PagedListView`) via `ref.watch`. Value-equal over [items] so
/// watchers rebuild only on a real content change.
@freezed
class PagedState<T> with _$PagedState<T> {
  /// Creates a [PagedState]. Defaults to the `idle` first-build state.
  const PagedState({
    this.items = const [],
    this.status = PagedStateStatus.idle,
    this.cursor,
    this.hasMore = true,
    this.error,
  });

  /// The typed items accumulated across all loaded pages.
  @override
  final List<T> items;

  /// The current lifecycle status.
  @override
  final PagedStateStatus status;

  /// The offset the next page should start at, or `null` when the last page
  /// loaded was the final one.
  @override
  final int? cursor;

  /// Whether another page may be available.
  @override
  final bool hasMore;

  /// The exception captured by the last failed fetch, or `null`.
  @override
  final Object? error;

  /// `true` while a subsequent page is in flight.
  bool get isLoadingNext => status == PagedStateStatus.loadingNext;

  /// `true` while the first page is in flight (initial load / refresh).
  bool get isLoading => status == PagedStateStatus.loading;

  /// `true` when the last fetch failed.
  bool get hasError => status == PagedStateStatus.error;

  /// `true` when the first page has resolved to zero items.
  bool get isEmpty => status == PagedStateStatus.ready && items.isEmpty && error == null;

  @override
  String toString() =>
      'PagedState(status: $status, items: ${items.length}, cursor: $cursor, '
      'hasMore: $hasMore, error: $error)';
}
