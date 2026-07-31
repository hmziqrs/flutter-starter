import 'package:flutter/foundation.dart';

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
@immutable
final class PagedResult<T> {
  const PagedResult({required this.items, this.nextCursor});

  /// The typed items in this page.
  final List<T> items;

  /// The offset the next page should start at, or `null` when this was the
  /// last page.
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

/// The typed port a `PagedStateNotifierBase` injects. The cursor is `null` for
/// the first page and the previous page's [PagedResult.nextCursor] thereafter.
typedef PageFetcher<T> = Future<PagedResult<T>> Function(int? cursor);

/// Immutable paged-list state, owned by `PagedStateNotifierBase` and consumed
/// by widgets (`PagedListView`) via `ref.watch`. Value-equal over [items] so
/// watchers rebuild only on a real content change.
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

  /// The typed items accumulated across all loaded pages.
  final List<T> items;

  /// The current lifecycle status.
  final PagedStateStatus status;

  /// The offset the next page should start at, or `null` when the last page
  /// loaded was the final one.
  final int? cursor;

  /// Whether another page may be available.
  final bool hasMore;

  /// The exception captured by the last failed fetch, or `null`.
  final Object? error;

  /// `true` while a subsequent page is in flight.
  bool get isLoadingNext => status == PagedStateStatus.loadingNext;

  /// `true` while the first page is in flight (initial load / refresh).
  bool get isLoading => status == PagedStateStatus.loading;

  /// `true` when the last fetch failed.
  bool get hasError => status == PagedStateStatus.error;

  /// `true` when the first page has resolved to zero items.
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
