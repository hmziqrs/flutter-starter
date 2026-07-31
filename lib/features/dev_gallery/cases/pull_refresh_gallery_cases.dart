import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/shared/widgets/lists/responsive_list_grid.dart';
import 'package:starter/shared/widgets/refresh/refreshable_list_view.dart';

enum PullRefreshGalleryState { refreshableList, responsiveGrid }

List<GalleryCase> buildPullRefreshGalleryCases() {
  return <GalleryCase>[
    TypedGalleryCase<PullRefreshGalleryState>(
      id: 'pullRefresh.list',
      screenId: 'pullRefresh',
      screenLabelBuilder: (translations) => translations.devGallery.screenPullRefresh,
      caseLabelBuilder: (translations) => translations.devGallery.casePullRefreshList,
      stateFactory: (_) => PullRefreshGalleryState.refreshableList,
      pageFactory: (context, state) => const _RefreshableListPreview(),
    ),
    TypedGalleryCase<PullRefreshGalleryState>(
      id: 'pullRefresh.grid',
      screenId: 'pullRefresh',
      screenLabelBuilder: (translations) => translations.devGallery.screenPullRefresh,
      caseLabelBuilder: (translations) => translations.devGallery.casePullRefreshGrid,
      stateFactory: (_) => PullRefreshGalleryState.responsiveGrid,
      pageFactory: (context, state) => const _ResponsiveGridPreview(),
    ),
  ];
}

final class _PreviewItem {
  const _PreviewItem(this.id, this.label);
  final String id;
  final String label;
}

const _previewItems = <_PreviewItem>[
  _PreviewItem('item-1', '01'),
  _PreviewItem('item-2', '02'),
  _PreviewItem('item-3', '03'),
  _PreviewItem('item-4', '04'),
  _PreviewItem('item-5', '05'),
  _PreviewItem('item-6', '06'),
  _PreviewItem('item-7', '07'),
  _PreviewItem('item-8', '08'),
];

Widget _previewCell(BuildContext context, _PreviewItem item) {
  return FCard(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Center(child: Text(item.label, style: context.theme.typography.display.lg)),
    ),
  );
}

class _RefreshableListPreview extends StatelessWidget {
  const _RefreshableListPreview();

  @override
  Widget build(BuildContext context) {
    return RefreshableListView<_PreviewItem>(
      items: _previewItems,
      itemBuilder: _previewCell,
      keyOf: (item) => item.id,
      onRefresh: () async {},
    );
  }
}

class _ResponsiveGridPreview extends StatelessWidget {
  const _ResponsiveGridPreview();

  @override
  Widget build(BuildContext context) {
    return ResponsiveListGrid<_PreviewItem>(
      items: _previewItems,
      itemBuilder: _previewCell,
      keyOf: (item) => item.id,
    );
  }
}
