import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import 'package:starter/shared/theme/brand_tokens.dart';

/// How much of the plan's allowance is used (APP-BLOCKS.md "UsageMeter"):
/// a primary fill on a muted track, with the share in words.
///
/// The fill changes color only when it means something: primary below the
/// warning level, warning from it, destructive at or over the limit. The
/// bar never carries text; the words always say the truth. Number strings
/// are composed in a fixed `en_US` format; pass [valueText] when the page
/// wants localized prose instead.
class AppUsageMeter extends StatelessWidget {
  const AppUsageMeter({
    required this.label,
    required this.used,
    required this.limit,
    required this.unit,
    this.valueText,
    this.resetsOn,
    this.warnAt = 0.8,
    this.limitMessage,
    this.action,
    this.noLimitText,
    super.key,
  });

  /// What is being measured, e.g. "Events this month".
  final String label;

  final num used;

  /// Null means no limit: the meter draws no bar and reads the words only.
  final num? limit;

  /// The unit word from the caller, e.g. "events".
  final String unit;

  /// The words under the bar, e.g. "7,420 of 10,000 events". When null,
  /// composed from the numbers as `used / limit unit`.
  final String? valueText;

  /// When the allowance starts over, e.g. "Resets on 1 November".
  final String? resetsOn;

  /// The share the warning color starts at.
  final double warnAt;

  /// The line shown at or over the limit, e.g. "You've used every event
  /// this month."
  final String? limitMessage;

  /// Shown beside the limit message, e.g. an "Upgrade" link.
  final Widget? action;

  /// The words for no limit, e.g. "No limit".
  final String? noLimitText;

  /// The fill color for the current share.
  @visibleForTesting
  Color fillColor(FThemeData theme) {
    if (limit != null && limit! > 0 && used >= limit!) {
      return theme.brand.destructive;
    }
    if (limit != null && limit! > 0 && used / limit! >= warnAt) {
      return theme.brand.warning;
    }
    return theme.colors.primary;
  }

  /// The share of the allowance used, clamped to 0–1 for drawing.
  @visibleForTesting
  double get share {
    if (limit == null || limit! <= 0) {
      return 0;
    }
    return (used / limit!).clamp(0.0, 1.0);
  }

  /// The words under the bar.
  @visibleForTesting
  String get resolvedValueText {
    if (valueText != null) {
      return valueText!;
    }
    if (limit == null) {
      return '${_whole.format(used)} $unit${noLimitText == null ? '' : ' \u00b7 $noLimitText'}';
    }
    return '${_whole.format(used)} / ${_whole.format(limit)} $unit';
  }

  static final NumberFormat _whole = NumberFormat.decimalPattern('en_US')
    ..maximumFractionDigits = 0;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final atLimit = limit != null && limit! > 0 && used >= limit!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          container: true,
          label: label,
          value: resolvedValueText,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                label,
                style: theme.typography.body.sm.copyWith(color: theme.colors.mutedForeground),
              ),
              const SizedBox(height: 8),
              if (limit != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: share,
                    minHeight: 6,
                    backgroundColor: theme.colors.muted,
                    valueColor: AlwaysStoppedAnimation(fillColor(theme)),
                  ),
                ),
              const SizedBox(height: 8),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 2,
                children: <Widget>[
                  Text(
                    resolvedValueText,
                    style: theme.typography.body.sm.copyWith(
                      color: theme.colors.foreground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (resetsOn != null)
                    Text(
                      resetsOn!,
                      style: theme.typography.body.sm.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (atLimit && limitMessage != null) ...<Widget>[
          const SizedBox(height: 8),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: <Widget>[
              Icon(FLucideIcons.circleAlert, size: 16, color: theme.brand.destructive),
              Text(
                limitMessage!,
                style: theme.typography.body.sm.copyWith(color: theme.brand.destructive),
              ),
              ?action,
            ],
          ),
        ],
      ],
    );
  }
}
