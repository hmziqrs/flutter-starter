import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/state/paged_state.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/states/empty_state_view.dart';
import 'package:starter/shared/widgets/states/error_state_view.dart';
import 'package:starter/shared/widgets/states/loading_state_view.dart';

const double _loadNextThresholdPixels = 240;

class PagedListView<T> extends StatelessWidget {
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

  final PagedState<T> state;

  final Widget Function(BuildContext context, T item) itemBuilder;

  final String Function(T item) keyOf;

  final Future<void> Function() onLoadNext;

  final Future<void> Function() onRefresh;

  final String emptyTitle;

  final String emptyBody;

  final String errorTitle;

  final String? errorBody;

  final EdgeInsetsGeometry? padding;

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
