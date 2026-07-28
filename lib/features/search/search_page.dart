import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/search/debounced_query_controller.dart';
import 'package:starter/features/search/search_view_data.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/state/paged_state.dart';
import 'package:starter/shared/state/paged_state_notifier.dart';
import 'package:starter/shared/theme/app_sizes.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/escape_dismissible_overlay.dart';
import 'package:starter/shared/widgets/lists/paged_list_view.dart';
import 'package:starter/shared/widgets/search/search_field.dart';

/// The local corpus the search field filters. Backend-free by design (the
/// feature spec: "search matches local data"); the default is the starter
/// fixture corpus — a real-local deterministic source (C2 note 2), NOT a faked
/// backend. A consumer with a real source overrides this at the composition
/// root; until then the app runs green with zero backend.
final searchCorpusProvider = Provider<List<SearchResultViewData>>(
  (ref) => SearchViewData.defaults().results,
);

/// Hand-written Riverpod [NotifierProvider] over the shared
/// [PagedStateNotifierBase]. Its [PageFetcher] filters [searchCorpusProvider]
/// by the live debounced query ([debouncedQueryProvider]) and slices the
/// matches into fixed-size pages — a real-local fetcher, not a faked source.
///
/// The fetcher is the C2 port for this paged surface. The no-backend default
/// ([noopPageFetcher]) surfaces `common.notConnected` and never synthesizes a
/// page; this controller wires a real-local fetcher so search demonstrates
/// pagination against the local corpus. A consumer with a server search
/// endpoint swaps the fetcher body for an HTTP call against the
/// `tools/test_server/` contract (audit #1).
final searchResultsControllerProvider =
    NotifierProvider<SearchResultsController, PagedState<SearchResultViewData>>(
      SearchResultsController.new,
    );

/// The page size the local fetcher slices the corpus into. Small enough that
/// the fixture corpus paginates (so [PagedListView]'s scroll-triggered
/// `loadNext` is exercised), large enough that the first page reads as a list.
const searchPageSize = 8;

final class SearchResultsController extends PagedStateNotifierBase<SearchResultViewData> {
  @override
  PageFetcher<SearchResultViewData> get fetcher => _fetch;

  List<SearchResultViewData> get _corpus => ref.read(searchCorpusProvider);
  String get _query => ref.read(debouncedQueryProvider);

  @override
  PagedState<SearchResultViewData> build() {
    // Re-fetch page one whenever the debounced query settles to a new value.
    // The list-side refresh fires only on a real change, so a no-op rebuild
    // never churns the paged state.
    ref.listen<String>(debouncedQueryProvider, (previous, next) {
      if (previous != next) {
        unawaited(refresh());
      }
    });
    return const PagedState<SearchResultViewData>();
  }

  Future<PagedResult<SearchResultViewData>> _fetch(int? cursor) async {
    final matches = _corpus.where((item) => item.matches(_query)).toList();
    final offset = cursor ?? 0;
    final page = matches.skip(offset).take(searchPageSize).toList();
    final nextOffset = offset + page.length;
    return PagedResult<SearchResultViewData>(
      items: page,
      nextCursor: nextOffset < matches.length ? nextOffset : null,
    );
  }
}

/// Full-screen in-app search route (top-level `GoRoute`, outside the shell).
///
/// Composes [SearchField] (debounced via [debouncedQueryProvider]),
/// [PagedListView] (driven by [searchResultsControllerProvider]), and the
/// shared state-views (empty / error / loading). The page owns its
/// [TextEditingController] and requests field focus on mount; Escape dismisses
/// the route via [EscapeDismissibleOverlay] (full-screen flow, audit #5).
///
/// Receives navigation callbacks (never calls `go_router` directly, per the root
/// contract). The corpus is local typed view-data (backend-free matching); a
/// consumer with a server search endpoint overrides [searchCorpusProvider] and
/// the fetcher body.
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({
    required this.onBack,
    this.autofocus = true,
    super.key,
  });

  /// Dismisses the search route. The router wires this to `context.pop()`.
  final VoidCallback onBack;

  /// Whether to focus the search field on mount. Defaults to true (the expected
  /// UX for a search route); the dev-gallery fixture passes false so the
  /// preview does not steal focus.
  final bool autofocus;

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Kick off the first page so the list is not stuck on the idle seed. The
      // controller surfaces loading → ready through state; navigation never
      // gates on it (audit #5).
      unawaited(ref.read(searchResultsControllerProvider.notifier).refresh());
      if (widget.autofocus) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final paged = ref.watch(searchResultsControllerProvider);
    final controller = ref.read(searchResultsControllerProvider.notifier);

    return EscapeDismissibleOverlay(
      child: FScaffold(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _SearchHeader(
                title: translations.search.title,
                onBack: widget.onBack,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppSizes.readingContentMaxWidth,
                    ),
                    child: SearchField(
                      controller: _textController,
                      focusNode: _focusNode,
                      hintText: translations.search.placeholder,
                      onChanged: (value) => ref.read(debouncedQueryProvider.notifier).set(value),
                      onSubmitted: () => _focusNode.unfocus(),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppSizes.wideContentMaxWidth,
                    ),
                    child: PagedListView<SearchResultViewData>(
                      state: paged,
                      itemBuilder: (context, item) => _SearchResultTile(
                        result: item,
                      ),
                      keyOf: (item) => item.id,
                      onLoadNext: controller.loadNext,
                      onRefresh: controller.refresh,
                      emptyTitle: translations.search.emptyTitle,
                      emptyBody: translations.search.emptyBody,
                      errorTitle: translations.search.errorTitle,
                      separator: const SizedBox(height: AppSpacing.sm),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          FButton.icon(
            key: const ValueKey('search-back'),
            variant: .ghost,
            semanticsLabel: context.t.common.back,
            onPress: onBack,
            child: const Icon(FLucideIcons.arrowLeft),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              title,
              key: const ValueKey('search-title'),
              style: context.theme.typography.display.lg,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.result});

  final SearchResultViewData result;

  @override
  Widget build(BuildContext context) {
    return FTile(
      key: ValueKey('search-result-${result.id}'),
      title: Text(
        result.title,
        key: ValueKey('search-result-${result.id}-title'),
      ),
      subtitle: result.subtitle.isEmpty ? null : Text(result.subtitle),
    );
  }
}
