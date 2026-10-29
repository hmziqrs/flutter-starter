import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/pricing/plan_view_data.dart';
import 'package:starter/shared/adaptive/app_unit.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/theme/brand_tokens.dart';
import 'package:starter/shared/widgets/containers/app_card.dart';

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
  /// every plan action stays an outline button; the card's border/fill still
  /// carries the selection.
  final bool primaryAction;

  @override
  Widget build(BuildContext context) {
    // Brand outline card (BRAND.md s8 pricing pattern): the user's picked
    // plan stands out through the selected recipe only — border primary/60 +
    // soft primary fill (BRAND.md s9 Selected). The recommended plan keeps an
    // unfilled outline card and is marked with the corner-ring fingerprint
    // instead of a card-wide wash.
    final recommended = plan.isRecommended && !selected;
    final colors = context.theme.colors;
    final softFillOpacity = colors.brightness == Brightness.dark ? 0.2 : 0.1;
    final spacing = context.spacing;
    final priceStyle = context.theme.typography.display.xl;
    return Semantics(
      selected: selected,
      enabled: onSelect != null,
      child: AppCard(
        key: ValueKey('plan-card-${plan.id}'),
        padding: EdgeInsets.all(spacing.xl),
        style: .delta(
          decoration: .shapeDelta(
            shape: RoundedSuperellipseBorder(
              side: BorderSide(
                color: selected ? colors.primary.withValues(alpha: 0.6) : colors.border,
                width: context.theme.style.borderWidth,
              ),
              borderRadius: context.theme.style.borderRadius.lg,
            ),
            color: selected ? colors.primary.withValues(alpha: softFillOpacity) : null,
          ),
        ),
        child: Stack(
          children: [
            // Full-bleed width: the Stack's loose fit would otherwise let the
            // column shrink to its widest child instead of the card width.
            SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: spacing.sm,
                    runSpacing: spacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Card titles run 18 w500 (APP-BLOCKS card/item title).
                      Text(plan.name, style: context.theme.typography.display.md),
                      if (plan.isRecommended)
                        // A soft primary tag, not a solid orange pill (BRAND.md
                        // s4: status is always soft; only orange is ever solid).
                        // It pairs with the corner-ring fingerprint below.
                        FBadge(
                          style: .delta(
                            decoration: .shapeDelta(
                              color: colors.primary.withValues(alpha: softFillOpacity),
                            ),
                            labelTextStyle: .delta(color: colors.primary),
                          ),
                          child: Text(recommendedLabel),
                        ),
                      if (plan.isCurrent)
                        FBadge(
                          variant: .outline,
                          // The outline badge keeps its line but loses the
                          // card-colored fill so it reads as a line on the outline
                          // card (BRAND.md s9: outline recipe is the line only).
                          style: .delta(
                            decoration: .value(
                              ShapeDecoration(
                                shape: RoundedSuperellipseBorder(
                                  side: BorderSide(
                                    color: colors.border,
                                    width: context.theme.style.borderWidth,
                                  ),
                                  borderRadius: context.theme.style.borderRadius.pill,
                                ),
                              ),
                            ),
                          ),
                          child: Text(currentLabel),
                        ),
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
                  SizedBox(height: spacing.sm),
                  Text(plan.description, style: context.theme.typography.body.sm),
                  SizedBox(height: spacing.xl),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.end,
                    spacing: spacing.sm,
                    children: [
                      // Big stat (APP-BLOCKS): 24 w500 tight — the display token
                      // carries 24/w500; the -0.02em tracking applies on top from
                      // the token's own size.
                      Text(
                        formattedPrice,
                        style: priceStyle.copyWith(
                          letterSpacing: (priceStyle.fontSize ?? 24) * -0.02,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: spacing.xs),
                        child: Text(periodLabel, style: context.theme.typography.body.sm),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.lg),
                  for (final benefit in plan.benefits) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: context.appUnit.snap(2)),
                          child: const Icon(FLucideIcons.check, size: 18),
                        ),
                        SizedBox(width: spacing.sm),
                        Expanded(child: Text(benefit)),
                      ],
                    ),
                    SizedBox(height: spacing.sm),
                  ],
                  SizedBox(height: spacing.md),
                  FButton(
                    key: ValueKey('select-plan-${plan.id}'),
                    // Solid primary only where this card carries the view's one
                    // main action; otherwise outline (line-only at rest).
                    variant: selected && primaryAction ? .primary : .outline,
                    // Non-primary actions are line-only at rest (no card-colored
                    // fill inside an outline card); the primary pick stays the one
                    // solid orange fill.
                    style: selected
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
                    builder: (_, _, _, _, _, child) => Flexible(child: child!),
                    child: Text(
                      actionLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            if (recommended)
              // The corner-ring fingerprint (BRAND.md s8): the ring motif's
              // border-colored track with one primary arc hugging the card's
              // end corner. Decorative — the meaning stays in the badge text.
              PositionedDirectional(
                top: 0,
                end: 0,
                width: _CornerRingFingerprint.extent,
                height: _CornerRingFingerprint.extent,
                child: ExcludeSemantics(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _CornerRingFingerprint(
                        trackColor: colors.border,
                        accentColor: colors.primary,
                        strokeWidth: context.theme.style.borderWidth * 2,
                        rtl: Directionality.of(context) == TextDirection.rtl,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The recommended plan's corner-ring fingerprint (BRAND.md s8): a small ring
/// whose center sits on the card's top-end corner, so only its inner quarter
/// shows — a hairline border-colored track with one primary arc.
class _CornerRingFingerprint extends CustomPainter {
  _CornerRingFingerprint({
    required this.trackColor,
    required this.accentColor,
    required this.strokeWidth,
    required this.rtl,
  });

  static const double extent = 20;
  static const double _radius = 16;

  final Color trackColor;
  final Color accentColor;
  final double strokeWidth;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    // The box is pinned to the card's top-end corner; the ring's center is
    // that corner, so the visible arc bends around it in both directions.
    final center = Offset(rtl ? 0 : size.width, 0);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    final accent = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = accentColor;

    canvas.drawCircle(center, _radius, track);
    // Sweep the quarter that faces the card's interior: from straight down
    // toward the start edge, so the accent hugs the corner's inside.
    final start = rtl ? math.pi / 2 : 0.0;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: _radius),
      start,
      math.pi / 2,
      false,
      accent,
    );
  }

  @override
  bool shouldRepaint(covariant _CornerRingFingerprint old) =>
      trackColor != old.trackColor ||
      accentColor != old.accentColor ||
      strokeWidth != old.strokeWidth ||
      rtl != old.rtl;
}
