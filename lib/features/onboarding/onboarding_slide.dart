import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/onboarding/onboarding_view_data.dart';
import 'package:starter/shared/adaptive/app_layout_class.dart';
import 'package:starter/shared/theme/app_presentation_tokens.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/brand/app_icon_tile.dart';
import 'package:starter/shared/widgets/rings/brand_rings.dart';

/// One onboarding slide, composed from the brand's signature pieces
/// (BRAND.md s7): the slide's own seeded hero rings as the visual, an
/// outline icon tile, and copy on the app type scale — a 24 w500 tight
/// title over a muted 14 body (APP-BLOCKS.md). No card fills; the page
/// itself is the surface.
///
/// The rings sit beside the words only (BRAND.md s13): compact has no room
/// for "beside", so the rings sit out and the outline icon tile carries the
/// visual — never a ring picture stacked into the slide's height. The rings
/// are still: an intro screen does not need movement, and the page
/// transition may animate. The same slide id always draws the same picture.
class OnboardingSlide extends StatelessWidget {
  const OnboardingSlide({required this.data, required this.layoutClass, super.key});

  final OnboardingSlideViewData data;
  final AppLayoutClass layoutClass;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final tokens = context.presentationTokens;
    final padding = EdgeInsetsDirectional.fromSTEB(spacing.xl, spacing.lg, spacing.xl, spacing.xl);

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        key: ValueKey('onboarding-slide-${data.id}'),
        padding: padding,
        child: ConstrainedBox(
          // Fill the viewport when there is room, so the composition centers
          // on tall screens and only scrolls when it must.
          constraints: BoxConstraints(
            minHeight: math.max(0, constraints.maxHeight - padding.top - padding.bottom),
          ),
          child: switch (layoutClass) {
            // Compact has no room for the rings beside the words, so they
            // sit out (BRAND.md s13): a centered column on the app type
            // scale, the outline icon tile carrying the visual.
            AppLayoutClass.compact => Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: tokens.formContentMaxWidth),
                child: _SlideCopy(data: data, centered: true),
              ),
            ),
            AppLayoutClass.medium => Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: tokens.readingContentMaxWidth),
                child: _beside(context, ringsMaxWidth: 320),
              ),
            ),
            AppLayoutClass.expanded => Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: tokens.wideContentMaxWidth),
                child: _beside(context, ringsMaxWidth: 440),
              ),
            ),
          },
        ),
      ),
    );
  }

  /// Words on the left, the rings beside them on the right — the web hero's
  /// arrangement (BRAND.md s8), used wherever the width has room for it.
  Widget _beside(BuildContext context, {required double ringsMaxWidth}) {
    final spacing = context.spacing;
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsetsDirectional.symmetric(vertical: spacing.xl2),
            child: _SlideCopy(data: data, centered: false),
          ),
        ),
        SizedBox(width: spacing.xl3),
        Expanded(
          child: _SlideRings(seed: data.id, maxWidth: ringsMaxWidth),
        ),
      ],
    );
  }
}

/// The slide's visual: its own hero rings, seeded from the slide id, capped
/// so the picture never crowds the copy. Decorative — excluded from
/// semantics by [BrandRings] itself.
class _SlideRings extends StatelessWidget {
  const _SlideRings({required this.seed, required this.maxWidth});

  /// The slide id: a stable seed, so every slide draws its own picture and
  /// the picture never changes between visits or languages.
  final String seed;

  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: BrandRings(seed: seed),
      ),
    );
  }
}

/// The slide's words on the app type scale: an outline icon tile, a 24 w500
/// tight title, and a muted 14 body held to a reading measure.
class _SlideCopy extends StatelessWidget {
  const _SlideCopy({required this.data, required this.centered});

  final OnboardingSlideViewData data;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final spacing = context.spacing;
    final tokens = context.presentationTokens;
    final titleSize = theme.typography.display.xl.fontSize ?? 24;
    final align = centered ? TextAlign.center : TextAlign.start;

    return Column(
      crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        AppIconTile(icon: _iconFor(data.visual)),
        SizedBox(height: spacing.lg),
        Text(
          data.title,
          textAlign: align,
          style: theme.typography.display.xl.copyWith(
            color: theme.colors.foreground,
            fontWeight: FontWeight.w500,
            // tracking-tight (-0.025em), the kit page intro's recipe.
            letterSpacing: -titleSize * 0.025,
          ),
        ),
        SizedBox(height: spacing.lg),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: tokens.formContentMaxWidth),
          child: Text(
            data.body,
            textAlign: align,
            style: theme.typography.body.sm.copyWith(color: theme.colors.mutedForeground),
          ),
        ),
      ],
    );
  }
}

IconData _iconFor(OnboardingVisual visual) => switch (visual) {
  OnboardingVisual.foundation => FLucideIcons.blocks,
  OnboardingVisual.adaptive => FLucideIcons.monitorSmartphone,
  OnboardingVisual.preferences => FLucideIcons.slidersHorizontal,
};
