import 'package:flutter/widgets.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/states/skeleton_tile.dart';
import 'package:starter/shared/widgets/states/skeleton_view.dart';

/// Immutable, deterministic preview state for the skeleton gallery cases.
///
/// One variant per shimmer path. No timers, no async work, no persistence
/// (C2: the gallery never fakes a backend action — a skeleton is a pure
/// loading treatment driven by an `isLoading` flag).
enum SkeletonGalleryState {
  /// The static (non-shimmering) path — reduce-motion and golden baseline.
  /// Forces `disableAnimations` so the preview is deterministic regardless of
  /// the gallery environment's animation toggle.
  staticList,

  /// The animated shimmer path — interactive preview only (never goldens).
  shimmerList,
}

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

/// Frames the skeleton list inside the gallery's constrained content column.
///
/// The static variant injects a `MediaQuery.disableAnimations` override so the
/// non-shimmering fallback paints deterministically (golden path). The shimmer
/// variant inherits the gallery environment's animation setting.
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
