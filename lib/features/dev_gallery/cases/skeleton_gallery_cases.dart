import 'package:flutter/widgets.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/states/skeleton_tile.dart';
import 'package:starter/shared/widgets/states/skeleton_view.dart';

enum SkeletonGalleryState { staticList, shimmerList }

List<GalleryCase> buildSkeletonGalleryCases() {
  return <GalleryCase>[
    TypedGalleryCase<SkeletonGalleryState>(
      id: 'skeleton.staticList',
      screenId: 'skeleton',
      screenLabelBuilder: (translations) => translations.devGallery.screenSkeleton,
      caseLabelBuilder: (translations) => translations.devGallery.caseSkeletonStatic,
      stateFactory: (_) => SkeletonGalleryState.staticList,
      pageFactory: (context, state) =>
          const _SkeletonPreview(state: SkeletonGalleryState.staticList),
    ),
    TypedGalleryCase<SkeletonGalleryState>(
      id: 'skeleton.shimmerList',
      screenId: 'skeleton',
      screenLabelBuilder: (translations) => translations.devGallery.screenSkeleton,
      caseLabelBuilder: (translations) => translations.devGallery.caseSkeletonShimmer,
      stateFactory: (_) => SkeletonGalleryState.shimmerList,
      pageFactory: (context, state) =>
          const _SkeletonPreview(state: SkeletonGalleryState.shimmerList),
    ),
  ];
}

class _SkeletonPreview extends StatelessWidget {
  const _SkeletonPreview({required this.state});

  final SkeletonGalleryState state;

  @override
  Widget build(BuildContext context) {
    final forceStatic = state == SkeletonGalleryState.staticList;
    final content = SkeletonView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (var index = 0; index < 3; index++) ...<Widget>[
            if (index > 0) const SizedBox(height: AppSpacing.sm),
            const SkeletonTile(),
          ],
        ],
      ),
    );

    if (!forceStatic) {
      return Center(
        child: Padding(padding: AppSpacing.screenPadding, child: content),
      );
    }

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: Center(
        child: Padding(padding: AppSpacing.screenPadding, child: content),
      ),
    );
  }
}
