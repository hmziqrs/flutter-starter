import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/states/skeleton_view.dart';

class SkeletonTile extends StatelessWidget {
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

  final double avatarSize;

  final double titleFraction;

  final double subtitleFraction;

  final bool includeSubtitle;

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return FCard(
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

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({
    this.iconSize = 20.0,
    this.lineCount = 2,
    this.titleFraction = 0.65,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    super.key,
  });

  final double iconSize;

  final int lineCount;

  final double titleFraction;

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return FCard(
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
