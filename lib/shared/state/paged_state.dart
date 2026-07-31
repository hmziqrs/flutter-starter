import 'package:freezed_annotation/freezed_annotation.dart';

part 'paged_state.freezed.dart';

enum PagedStateStatus { idle, loading, ready, loadingNext, error }

enum PagedFetchFailureKind { notConnected }

final class PagedFetchException implements Exception {
  const PagedFetchException._(this.kind);

  factory PagedFetchException.notConnected() =>
      const PagedFetchException._(PagedFetchFailureKind.notConnected);

  final PagedFetchFailureKind kind;

  @override
  String toString() => 'PagedFetchException: ${kind.name}';
}

@freezed
class PagedResult<T> with _$PagedResult<T> {
  const PagedResult({required this.items, this.nextCursor});

  @override
  final List<T> items;

  @override
  final int? nextCursor;

  @override
  String toString() => 'PagedResult(items: ${items.length}, nextCursor: $nextCursor)';
}

typedef PageFetcher<T> = Future<PagedResult<T>> Function(int? cursor);

@freezed
class PagedState<T> with _$PagedState<T> {
  const PagedState({
    this.items = const [],
    this.status = PagedStateStatus.idle,
    this.cursor,
    this.hasMore = true,
    this.error,
  });

  @override
  final List<T> items;

  @override
  final PagedStateStatus status;

  @override
  final int? cursor;

  @override
  final bool hasMore;

  @override
  final Object? error;

  bool get isLoadingNext => status == PagedStateStatus.loadingNext;

  bool get isLoading => status == PagedStateStatus.loading;

  bool get hasError => status == PagedStateStatus.error;

  bool get isEmpty => status == PagedStateStatus.ready && items.isEmpty && error == null;

  @override
  String toString() =>
      'PagedState(status: $status, items: ${items.length}, cursor: $cursor, '
      'hasMore: $hasMore, error: $error)';
}
