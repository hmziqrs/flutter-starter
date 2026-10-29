import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/widgets/blocks/metric_trend.dart';

/// One number that matters (APP-BLOCKS.md "StatCard"): an outline card with
/// the label in muted words, the value as the big stat — 24, w500, tight —
/// and an optional trend and hint line.
///
/// No fill, no shadow: the same thin border on all four sides as every
/// surface that sits in the page. The value arrives already formatted.
class AppStatCard extends StatelessWidget {
  const AppStatCard({
    required this.label,
    required this.value,
    this.trend,
    this.hint,
    super.key,
  });

  final String label;

  /// The number, already formatted by the caller: "48,210", "42.1%", "1.8 s".
  final String value;

  /// The change under the number, if it moved.
  final AppMetricTrend? trend;

  /// One line under the number.
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: Colors.transparent,
        shape: RoundedSuperellipseBorder(
          side: BorderSide(color: theme.colors.border, width: theme.style.borderWidth),
          borderRadius: theme.style.borderRadius.lg,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.typography.body.sm.copyWith(color: theme.colors.mutedForeground),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: theme.typography.display.xl.copyWith(
              color: theme.colors.foreground,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.02 * (theme.typography.display.xl.fontSize ?? 24),
            ),
          ),
          if (trend != null) ...<Widget>[const SizedBox(height: 10), trend!],
          if (hint != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              hint!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.typography.body.sm.copyWith(color: theme.colors.mutedForeground),
            ),
          ],
        ],
      ),
    );
  }
}
