import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/shared/widgets/lists/responsive_list_grid.dart';
import 'package:starter/shared/widgets/refresh/refreshable_list_view.dart';

/// Immutable, deterministic preview state for the pull-refresh gallery cases.
/// One variant per previewed surface; no timers, no plugin, no persistence
/// (C2: the gallery never fakes a backend action — the refresh `onRefresh`
/// completes a no-op Future as a preview affordance, never a claim of success).
enum PullRefreshGalleryState {
  /// A refreshable lazy list.
  refreshableList,

  /// A responsive grid that reflows on width.
  responsiveGrid,
}

/// Builds the pull-refresh gallery cases: a refreshable lazy list and a
/// responsive grid. Every case is a static fixture — the refresh `onRefresh`
/// completes a no-op preview Future; a real call site surfaces
/// `common.notConnected` rather than faking a successful refresh (audit #13).
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

/// A preview item rendered as a themed card cell.
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

/// Mounts a [RefreshableListView] with a no-op preview refresh. The
/// PreviewFrame supplies the Material ancestor the indicator needs, so the drag
/// gesture and accent spinner are real; the `onRefresh` completes a no-op
/// Future (the gallery never fakes a backend action).
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

/// Mounts a [ResponsiveListGrid]. The PreviewFrame already nests an
/// `AppLayoutScope`, so the grid reflows (1 / 2 / 3 columns) as the gallery
/// viewport width changes.
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
