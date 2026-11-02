import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/brand_tokens.dart';
import 'package:starter/shared/widgets/blocks/copy_button.dart';
import 'package:starter/shared/widgets/rings/status_ring.dart';

/// One webhook delivery: the `event` name, the HTTP `status` it answered
/// with, and the `at` time it ran, in the caller's words.
typedef AppEndpointDelivery = ({String event, int status, String at});

/// One number that matters: the `label` under which the `value` shows.
typedef AppEndpointMetric = ({String label, String value});

/// A webhook endpoint's health (endpoint-card.svelte): its state word beside
/// a spinning status ring, the address in a copyable inset, a bar per day
/// for the last month, the numbers that matter under the chart, the latest
/// deliveries, and the actions that act on the endpoint.
///
/// A day is the `days` share delivered on the first try, 0–1, oldest first:
/// at least 99.5% reads good (a quiet bar), at least 95% slow (a warning
/// bar), anything less down (a destructive bar). The state word — Healthy,
/// Some retries, Failing — comes from the last day.
class AppEndpointCard extends StatelessWidget {
  const AppEndpointCard({
    required this.url,
    required this.days,
    required this.metrics,
    required this.primaryLabel,
    this.onPrimary,
    this.deliveries = const <AppEndpointDelivery>[],
    this.secondaryLabel,
    this.onSecondary,
    this.startLabel = '',
    this.endLabel = 'Today',
    super.key,
  });

  /// The endpoint's address, shown in the inset and put on the clipboard.
  final String url;

  /// One share per day, oldest first; see the class doc for the bands.
  final List<double> days;

  /// The numbers under the chart, one column each, e.g. first-try share,
  /// median time, retries.
  final List<AppEndpointMetric> metrics;

  /// The footer's primary action's label, e.g. `Send a test event`.
  final String primaryLabel;

  /// The footer's primary action.
  final VoidCallback? onPrimary;

  /// The latest deliveries, newest first.
  final List<AppEndpointDelivery> deliveries;

  /// The footer's second action's label, e.g. `Pause`; without it only the
  /// primary button shows.
  final String? secondaryLabel;

  /// The footer's second action.
  final VoidCallback? onSecondary;

  /// The caption under the chart's start edge, e.g. the first day's date.
  final String startLabel;

  /// The caption under the chart's end edge.
  final String endLabel;

  /// At least this share on the first try reads good.
  static const double _goodAt = 0.995;

  /// At least this share (and under good) reads slow.
  static const double _slowAt = 0.95;

  /// Whether [share] is good, slow or down.
  static bool _isGood(double share) => share >= _goodAt;

  static bool _isSlow(double share) => share >= _slowAt && !_isGood(share);

  static bool _isDown(double share) => !_isGood(share) && !_isSlow(share);

  /// The bar's height as a share of the chart: the delivered share, pulled
  /// down by retries but never under 18% (endpoint-card.svelte's
  /// `Math.max(18, d * 100 - (1 - d) * 400)`).
  static double _barExtent(double share) =>
      (share * 100 - (1 - share) * 400).clamp(18.0, 100.0) / 100;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final brand = theme.brand;
    final last = days.isEmpty ? 1.0 : days.last;
    final down = _isDown(last);
    final stateColor = down ? null : (_isGood(last) ? brand.success : brand.warning);
    final word = down ? 'Failing' : (_isGood(last) ? 'Healthy' : 'Some retries');
    final border = BorderSide(color: theme.colors.border, width: theme.style.borderWidth);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: Colors.transparent,
        shape: RoundedSuperellipseBorder(
          // The card's ring is the foreground at 10%
          // (endpoint-card.svelte ring-1 ring-foreground/10).
          side: BorderSide(
            color: theme.colors.foreground.withValues(alpha: 0.10),
            width: theme.style.borderWidth,
          ),
          borderRadius: theme.style.borderRadius.lg,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: 12,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    // The ring runs 1em of the state word's 14dp (size-[1em]).
                    StatusRing(active: !down, stale: down, color: stateColor),
                    const SizedBox(width: 8),
                    // The state word carries the slack and ellipsizes before
                    // the row could ever push the day count out.
                    Expanded(
                      child: Text(
                        word,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.typography.body.sm.copyWith(
                          color: theme.colors.foreground,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Last ${days.length} days',
                      style: theme.typography.body.xs.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
                // The address inset (rounded-lg border py-1 pr-1 pl-3.5):
                // plain 13dp mono, the ghost copy at its end.
                Container(
                  padding: const EdgeInsetsDirectional.only(start: 14, end: 4, top: 4, bottom: 4),
                  decoration: ShapeDecoration(
                    color: Colors.transparent,
                    shape: RoundedSuperellipseBorder(
                      side: border,
                      borderRadius: theme.style.borderRadius.md,
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          url,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            inherit: false,
                            color: theme.colors.foreground,
                            fontFamily: 'JetBrains Mono',
                            fontSize: 13,
                            height: 1.7,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      AppCopyButton(text: url, label: 'Copy URL', copiedLabel: 'Copied'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  // The chart: one bar per day, 3dp apart, growing from the
                  // baseline (h-10 items-end gap-[3px]).
                  height: 40,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    spacing: 3,
                    children: <Widget>[
                      for (final share in days)
                        Expanded(
                          child: FractionallySizedBox(
                            heightFactor: _barExtent(share),
                            alignment: AlignmentDirectional.bottomStart,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: _isGood(share)
                                    ? theme.colors.foreground.withValues(alpha: 0.25)
                                    : _isSlow(share)
                                    ? brand.warning
                                    : brand.destructive,
                                borderRadius: const BorderRadius.all(Radius.circular(2)),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  // mt-1.5 under the bars: the day captions.
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      if (startLabel.isNotEmpty)
                        Flexible(
                          child: Text(
                            startLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                        ),
                      Flexible(
                        child: Text(
                          endLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // The numbers that matter: equal columns split by the card's
          // hairline (grid border-y, border-l between cells), 24dp of side
          // air and 16dp of vertical air per cell.
          Container(
            margin: const EdgeInsets.only(top: 20),
            decoration: BoxDecoration(
              border: Border(top: border, bottom: border),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (final (index, metric) in metrics.indexed) ...<Widget>[
                    if (index > 0)
                      VerticalDivider(width: 1, thickness: border.width, color: border.color),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          spacing: 2,
                          children: <Widget>[
                            Text(
                              metric.label,
                              style: theme.typography.body.xs.copyWith(
                                color: theme.colors.mutedForeground,
                              ),
                            ),
                            Text(
                              metric.value,
                              style: TextStyle(
                                fontSize: 18,
                                height: 1.33,
                                letterSpacing: -0.025 * 18,
                                fontWeight: FontWeight.w500,
                                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                                color: theme.colors.foreground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (deliveries.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (final (index, delivery) in deliveries.indexed) ...<Widget>[
                  if (index > 0) Divider(height: 1, thickness: border.width, color: border.color),
                  Padding(
                    // One delivery row: the status chip, the event in mono,
                    // the time pushed to the end (px-6 py-2.5).
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    child: Row(
                      children: <Widget>[
                        _StatusChip(status: delivery.status),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            delivery.event,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              inherit: false,
                              color: theme.colors.foreground,
                              fontFamily: 'JetBrains Mono',
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          delivery.at,
                          style: theme.typography.body.xs.copyWith(
                            color: theme.colors.mutedForeground,
                            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          Container(
            decoration: BoxDecoration(border: Border(top: border)),
            padding: const EdgeInsets.all(16),
            // The buttons stay intrinsic (the kit's flex gap-2 with sm
            // buttons); a Wrap carries them, so a narrow card (or wider
            // fallback glyphs) moves the second action to its own line
            // instead of clipping it.
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                FButton(
                  size: FButtonSizeVariant.sm,
                  // Hug the label like the kit's flex row of sm buttons —
                  // FButton's MainAxisSize.max default would stretch each
                  // action across the card and stack the row.
                  mainAxisSize: MainAxisSize.min,
                  onPress: onPrimary,
                  child: Text(primaryLabel),
                ),
                if (secondaryLabel != null)
                  FButton(
                    size: FButtonSizeVariant.sm,
                    mainAxisSize: MainAxisSize.min,
                    variant: FButtonVariant.outline,
                    onPress: onSecondary,
                    child: Text(secondaryLabel!),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final int status;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final good = status < 300;
    final color = good ? theme.brand.success : theme.brand.warning;
    final fillOpacity = theme.colors.brightness == Brightness.dark ? 0.20 : 0.10;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: ShapeDecoration(
        color: color.withValues(alpha: fillOpacity),
        shape: RoundedSuperellipseBorder(borderRadius: theme.style.borderRadius.xs2),
      ),
      child: Text(
        '$status',
        style: TextStyle(
          inherit: false,
          color: color,
          fontFamily: 'JetBrains Mono',
          fontSize: 12,
          height: 1.33,
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
