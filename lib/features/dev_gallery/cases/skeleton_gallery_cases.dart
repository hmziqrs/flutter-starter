import 'package:flutter/widgets.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/states/skeleton_tile.dart';
import 'package:starter/shared/widgets/states/skeleton_view.dart';

enum SkeletonGalleryState { staticList, shimmerList }

/// Builds the skeleton gallery cases: a static reduce-motion list (the golden
/// baseline) and an animated shimmer list. Both preview the same mirrored
/// layout (three [SkeletonTile]s inside a [SkeletonView]).
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

/// The static variant forces `disableAnimations` so the non-shimmering
/// fallback paints deterministically for goldens; the shimmer variant
/// inherits the gallery environment's animation setting.
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
        child: Padding(padding: const EdgeInsets.all(AppSpacing.xl), child: content),
      );
    }

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: Center(
        child: Padding(padding: const EdgeInsets.all(AppSpacing.xl), child: content),
      ),
    );
  }
}
