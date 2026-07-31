import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/state/paged_state.dart';
import 'package:starter/shared/state/paged_state_notifier.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/lists/paged_list_view.dart';
import 'package:starter/shared/widgets/search/search_field.dart';

enum SearchPaginationGalleryState { searchField, pagedList, pagedListNoBackend }

List<GalleryCase> buildSearchPaginationGalleryCases() {
  return <GalleryCase>[
    TypedGalleryCase<SearchPaginationGalleryState>(
      id: 'searchPagination.field',
      screenId: 'searchPagination',
      screenLabelBuilder: (t) => t.devGallery.screenSearchPagination,
      caseLabelBuilder: (t) => t.devGallery.caseSearchField,
      stateFactory: (_) => SearchPaginationGalleryState.searchField,
      pageFactory: (context, state) => const _GallerySearchFieldPreview(),
    ),
    TypedGalleryCase<SearchPaginationGalleryState>(
      id: 'searchPagination.paged',
      screenId: 'searchPagination',
      screenLabelBuilder: (t) => t.devGallery.screenSearchPagination,
      caseLabelBuilder: (t) => t.devGallery.caseSearchPaged,
      stateFactory: (_) => SearchPaginationGalleryState.pagedList,
      pageFactory: (context, state) => const _GalleryPagedPreview(noop: false),
    ),
    TypedGalleryCase<SearchPaginationGalleryState>(
      id: 'searchPagination.pagedNoBackend',
      screenId: 'searchPagination',
      screenLabelBuilder: (t) => t.devGallery.screenSearchPagination,
      caseLabelBuilder: (t) => t.devGallery.caseSearchPagedNoBackend,
      stateFactory: (_) => SearchPaginationGalleryState.pagedListNoBackend,
      pageFactory: (context, state) => const _GalleryPagedPreview(noop: true),
    ),
  ];
}

@immutable
final class _GalleryPagedItem {
  const _GalleryPagedItem(this.id, this.label);
  final String id;
  final String label;
}

const _galleryItems = <_GalleryPagedItem>[
  _GalleryPagedItem('gallery-row-01', 'Row 01'),
  _GalleryPagedItem('gallery-row-02', 'Row 02'),
  _GalleryPagedItem('gallery-row-03', 'Row 03'),
  _GalleryPagedItem('gallery-row-04', 'Row 04'),
  _GalleryPagedItem('gallery-row-05', 'Row 05'),
  _GalleryPagedItem('gallery-row-06', 'Row 06'),
  _GalleryPagedItem('gallery-row-07', 'Row 07'),
  _GalleryPagedItem('gallery-row-08', 'Row 08'),
  _GalleryPagedItem('gallery-row-09', 'Row 09'),
  _GalleryPagedItem('gallery-row-10', 'Row 10'),
  _GalleryPagedItem('gallery-row-11', 'Row 11'),
  _GalleryPagedItem('gallery-row-12', 'Row 12'),
  _GalleryPagedItem('gallery-row-13', 'Row 13'),
  _GalleryPagedItem('gallery-row-14', 'Row 14'),
  _GalleryPagedItem('gallery-row-15', 'Row 15'),
  _GalleryPagedItem('gallery-row-16', 'Row 16'),
  _GalleryPagedItem('gallery-row-17', 'Row 17'),
  _GalleryPagedItem('gallery-row-18', 'Row 18'),
  _GalleryPagedItem('gallery-row-19', 'Row 19'),
  _GalleryPagedItem('gallery-row-20', 'Row 20'),
];

final _galleryPopulatedPagedProvider =
    NotifierProvider<_GalleryPopulatedNotifier, PagedState<_GalleryPagedItem>>(
      _GalleryPopulatedNotifier.new,
    );

final class _GalleryPopulatedNotifier extends PagedStateNotifierBase<_GalleryPagedItem> {
  @override
  PageFetcher<_GalleryPagedItem> get fetcher => _fetch;

  Future<PagedResult<_GalleryPagedItem>> _fetch(int? cursor) async {
    const pageSize = 8;
    final offset = cursor ?? 0;
    final page = _galleryItems.skip(offset).take(pageSize).toList();
    final next = offset + page.length;
    return PagedResult<_GalleryPagedItem>(
      items: page,
      nextCursor: next < _galleryItems.length ? next : null,
    );
  }
}

final _galleryNoopPagedProvider =
    NotifierProvider<_GalleryNoopNotifier, PagedState<_GalleryPagedItem>>(
      _GalleryNoopNotifier.new,
    );

final class _GalleryNoopNotifier extends PagedStateNotifierBase<_GalleryPagedItem> {
  @override
  PageFetcher<_GalleryPagedItem> get fetcher => noopPageFetcher<_GalleryPagedItem>();
}

class _GallerySearchFieldPreview extends StatefulWidget {
  const _GallerySearchFieldPreview();

  @override
  State<_GallerySearchFieldPreview> createState() => _GallerySearchFieldPreviewState();
}

class _GallerySearchFieldPreviewState extends State<_GallerySearchFieldPreview> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                context.t.search.title,
                style: context.theme.typography.display.lg,
              ),
              const SizedBox(height: AppSpacing.md),
              SearchField(
                controller: _controller,
                hintText: context.t.search.placeholder,
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GalleryPagedPreview extends ConsumerStatefulWidget {
  const _GalleryPagedPreview({required this.noop});

  final bool noop;

  @override
  ConsumerState<_GalleryPagedPreview> createState() => _GalleryPagedPreviewState();
}

class _GalleryPagedPreviewState extends ConsumerState<_GalleryPagedPreview> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(
        widget.noop ? _galleryNoopPagedProvider.notifier : _galleryPopulatedPagedProvider.notifier,
      );
      unawaited(notifier.refresh());
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.noop ? _galleryNoopPagedProvider : _galleryPopulatedPagedProvider;
    final paged = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    return PagedListView<_GalleryPagedItem>(
      state: paged,
      itemBuilder: (context, item) => FTile(
        key: ValueKey('gallery-paged-${item.id}'),
        title: Text(item.label),
      ),
      keyOf: (item) => item.id,
      onLoadNext: controller.loadNext,
      onRefresh: controller.refresh,
      emptyTitle: context.t.search.emptyTitle,
      emptyBody: context.t.search.emptyBody,
      errorTitle: context.t.search.errorTitle,
      separator: const SizedBox(height: AppSpacing.sm),
    );
  }
}
