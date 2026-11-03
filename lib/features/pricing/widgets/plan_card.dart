import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/pricing/plan_view_data.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/theme/brand_tokens.dart';
import 'package:starter/shared/widgets/brand/app_ring_marker.dart';
import 'package:starter/shared/widgets/brand/app_status_tag.dart';
import 'package:starter/shared/widgets/containers/app_card.dart';
import 'package:starter/shared/widgets/rings/corner_rings.dart';

class PlanCard extends StatelessWidget {
  const PlanCard({
    required this.plan,
    required this.formattedPrice,
    required this.periodLabel,
    required this.actionLabel,
    required this.recommendedLabel,
    required this.currentLabel,
    required this.selected,
    required this.onSelect,
    this.unavailableLabel,
    this.primaryAction = true,
    super.key,
  });

  final PlanViewData plan;
  final String formattedPrice;
  final String periodLabel;
  final String actionLabel;
  final String recommendedLabel;
  final String currentLabel;
  final bool selected;
  final VoidCallback? onSelect;
  final String? unavailableLabel;

  /// Whether the selected plan's action is the view's one solid primary
  /// button (BRAND.md s4: never more than one main button per view). Views
  /// with their own primary action — the paywall's Continue — set false so
  /// every plan action stays an outline button; the card's border still
  /// carries the selection.
  final bool primaryAction;

  @override
  Widget build(BuildContext context) {
    // The brand pricing plan (pricing-plans.svelte): outline cards; the
    // recommended card carries its corner-ring fingerprint and the orange
    // line in both templates — selection adds the same orange line to
    // whichever card the visitor picks. No card-wide wash anywhere.
    final recommended = plan.isRecommended;
    final colors = context.theme.colors;
    final softFillOpacity = colors.brightness == Brightness.dark ? 0.2 : 0.1;
    final spacing = context.spacing;
    return Semantics(
      selected: selected,
      enabled: onSelect != null,
      child: LayoutBuilder(
        builder: (context, constraints) => AppCard(
          key: ValueKey('plan-card-${plan.id}'),
          // The corner rings paint to the card's edge; the outline card
          // clips them like the kit's overflow-hidden tiles. Padding is
          // zero here so the fingerprint can converge on the card's own
          // corner (corner-rings.svelte anchors at inset 0) — the content
          // carries the card's air instead.
          clipBehavior: Clip.antiAlias,
          padding: EdgeInsets.zero,
          style: .delta(
            decoration: .shapeDelta(
              shape: RoundedSuperellipseBorder(
                side: BorderSide(
                  color: (selected || recommended)
                      ? colors.primary.withValues(alpha: 0.55)
                      : colors.border,
                  width: context.theme.style.borderWidth,
                ),
                borderRadius: context.theme.style.borderRadius.lg,
              ),
            ),
          ),
          child: Stack(
            children: [
              if (recommended)
                // The corner-ring fingerprint (pricing-plans.svelte puts
                // `CornerRings quiet` in the picked plan): eight faint rings
                // seeded `pricing {name}` with one orange arc, converging on
                // the card's end corner. Decorative — the meaning stays in
                // the tag's text.
                PositionedDirectional(
                  top: 0,
                  end: 0,
                  width: constraints.maxWidth * 0.7,
                  height: constraints.maxWidth * 0.7,
                  child: ExcludeSemantics(
                    child: IgnorePointer(
                      child: Transform.flip(
                        flipX: Directionality.of(context) == TextDirection.rtl,
                        child: CornerRings(
                          seed: 'pricing ${plan.name}',
                          quiet: true,
                          size: constraints.maxWidth * 0.7,
                        ),
                      ),
                    ),
                  ),
                ),
              // Full-bleed width: the Stack's loose fit would otherwise let the
              // column shrink to its widest child instead of the card width.
              Padding(
                padding: EdgeInsets.all(spacing.xl),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    // gap-4: the kit's one rhythm between the plan's blocks.
                    spacing: spacing.lg,
                    children: [
                      Wrap(
                        spacing: spacing.sm,
                        runSpacing: spacing.sm,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // The plan's name: text-lg font-medium — 18 w500
                          // (pricing-plans.svelte's h3).
                          Text(
                            plan.name,
                            style: context.theme.typography.body.lg.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (plan.isRecommended)
                            // A soft orange tag with its ring marker, like the
                            // kit's `<Tag tone="orange" marker>` (BRAND.md s4:
                            // status is always soft; only orange is ever solid).
                            _RecommendedTag(label: recommendedLabel),
                          if (plan.isCurrent)
                            // The kit's plain grey tag: "Current" is a neutral
                            // state, and the pricing pattern has no material
                            // pill of its own (BRAND.md s8: tech/status labels
                            // stay grey; only real status takes a color).
                            AppStatusTag(label: currentLabel),
                          if (unavailableLabel case final label?)
                            // Soft destructive tag resolved from the brand palette so
                            // the red matches BRAND.md s4 in both modes (the theme's
                            // light destructive is not the brand red).
                            FBadge(
                              variant: .destructive,
                              style: .delta(
                                decoration: .shapeDelta(
                                  color: context.theme.brand.destructive.withValues(
                                    alpha: softFillOpacity,
                                  ),
                                ),
                                labelTextStyle: .delta(color: context.theme.brand.destructive),
                              ),
                              child: Text(label),
                            ),
                        ],
                      ),
                      // The price: text-[2.5rem] font-medium tracking-[-0.04em],
                      // the period in 14.4dp grey after it.
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.end,
                        spacing: spacing.sm,
                        children: [
                          Text(
                            formattedPrice,
                            style: TextStyle(
                              fontSize: 40,
                              height: 1.15,
                              letterSpacing: 40 * -0.04,
                              fontWeight: FontWeight.w500,
                              color: colors.foreground,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(bottom: spacing.xs),
                            child: Text(
                              periodLabel,
                              style: TextStyle(
                                fontSize: 14.4,
                                color: colors.mutedForeground,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        plan.description,
                        style: TextStyle(fontSize: 14.4, color: colors.mutedForeground),
                      ),
                      // CheckList: a filled orange ring before each item, the
                      // words in 14dp grey, 12dp between items (gap-3).
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        spacing: spacing.md,
                        children: [
                          for (final benefit in plan.benefits)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                AppRingMarker(filled: true, color: colors.primary),
                                SizedBox(width: spacing.md),
                                Expanded(
                                  child: Text(
                                    benefit,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: colors.mutedForeground,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      // The action stretches the card's width, like the other
                      // blocks (the kit's ButtonLink rides the column too).
                      SizedBox(
                        width: double.infinity,
                        child: FButton(
                          key: ValueKey('select-plan-${plan.id}'),
                          // Solid primary only where this card carries the view's one
                          // main action; otherwise outline (line-only at rest).
                          variant: selected && primaryAction ? .primary : .outline,
                          // Brand outline recipe (BRAND.md s9, s13): an outline
                          // button is a line at rest in both modes — no fill.
                          // ForUI's inherit fills the outline variant with the
                          // card color, which reads as a grey-filled control in
                          // dark mode, so every non-primary action (selected or
                          // not) strips the rest state's fill; hover and press
                          // deltas stay inherited so feedback is color-only.
                          // The card's border still carries the selection.
                          style: selected && primaryAction
                              ? const .delta(
                                  tappableStyle: .delta(
                                    motion: .delta(bounceTween: FTappableMotion.noBounceTween),
                                  ),
                                )
                              : .delta(
                                  decoration: .delta([
                                    .base(
                                      DecorationDelta.value(
                                        ShapeDecoration(
                                          shape: RoundedSuperellipseBorder(
                                            side: BorderSide(
                                              color: colors.border,
                                              width: context.theme.style.borderWidth,
                                            ),
                                            borderRadius: context.theme.style.borderRadius.md,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ]),
                                  tappableStyle: const .delta(
                                    motion: .delta(bounceTween: FTappableMotion.noBounceTween),
                                  ),
                                ),
                          onPress: onSelect,
                          child: Text(
                            actionLabel,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
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

/// The recommended plan's tag: the soft orange pill with its hollow ring
/// marker (tag.svelte: h-5 rounded-4xl px-2, bg-orange/10 — /20 in dark —
/// text-orange, the marker a 7dp ring).
class _RecommendedTag extends StatelessWidget {
  const _RecommendedTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final color = theme.brand.oxide;
    final fillOpacity = theme.colors.brightness == Brightness.dark ? 0.20 : 0.10;
    return Container(
      constraints: const BoxConstraints(minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: ShapeDecoration(
        color: color.withValues(alpha: fillOpacity),
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppRingMarker(color: color, size: 7, borderWidth: 1.5),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.typography.body.xs.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
