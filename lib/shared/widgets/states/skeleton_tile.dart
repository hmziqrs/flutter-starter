import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/states/skeleton_view.dart';

/// A skeleton bone mirroring an [FTile] / [FCard] row: a leading circular
/// avatar, a primary line, and an optional secondary line.
///
/// Built entirely from bone primitives ([SkeletonCircle], [SkeletonLine]) so it
/// inherits the ancestor [SkeletonView] shimmer (or the static reduce-motion
/// fill) with no extra wiring. The shape tracks a typical list tile so a column
/// of these mirrors a loading list (e.g. home recent activity, search results,
/// cached feeds) — keep the mirrored layout in sync with the production tile.
///
/// Pure presentational: no state, no plugin calls, no side effects.
class SkeletonTile extends StatelessWidget {
  /// Creates a [SkeletonTile].
  const SkeletonTile({
    this.avatarSize = 32.0,
    this.titleFraction = 0.55,
    this.subtitleFraction = 0.85,
    this.includeSubtitle = true,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
    super.key,
  });

  /// Leading avatar diameter.
  final double avatarSize;

  /// Title-line width as a fraction of the available width.
  final double titleFraction;

  /// Subtitle-line width as a fraction of the available width.
  final double subtitleFraction;

  /// When `false`, only the title line is rendered.
  final bool includeSubtitle;

  /// Interior padding around the tile content.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return FCard(
      // Stable identity for widget/integration tests and gallery previews.
      key: const ValueKey('skeleton-tile'),
      child: Padding(
        padding: padding,
        child: Row(
          children: <Widget>[
            SkeletonCircle(size: avatarSize),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SkeletonLine(widthFraction: titleFraction),
                  if (includeSubtitle) ...<Widget>[
                    const SizedBox(height: AppSpacing.xs),
                    SkeletonLine(widthFraction: subtitleFraction, height: 10),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A skeleton bone mirroring a content [FCard]: a leading icon box, a title
/// line, and one or more body lines.
///
/// Grids of these mirror status-card layouts (e.g. the home status section) and
/// feature-card grids while data loads. Like [SkeletonTile], it composes bone
/// primitives and inherits the ancestor [SkeletonView] shimmer or the static
/// reduce-motion fill.
class SkeletonCard extends StatelessWidget {
  /// Creates a [SkeletonCard].
  const SkeletonCard({
    this.iconSize = 20.0,
    this.lineCount = 2,
    this.titleFraction = 0.65,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    super.key,
  });

  /// Leading icon bone edge length.
  final double iconSize;

  /// Number of body lines rendered beneath the title.
  final int lineCount;

  /// Title-line width fraction.
  final double titleFraction;

  /// Interior padding around the card content.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return FCard(
      // Stable identity for widget/integration tests and gallery previews.
      key: const ValueKey('skeleton-card'),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SkeletonBox(width: iconSize, height: iconSize),
            const SizedBox(height: AppSpacing.md),
            SkeletonLine(widthFraction: titleFraction),
            for (var index = 0; index < lineCount; index++) ...<Widget>[
              const SizedBox(height: AppSpacing.xs),
              SkeletonLine(
                height: 10,
                widthFraction: index == lineCount - 1 ? 0.6 : 1.0,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
