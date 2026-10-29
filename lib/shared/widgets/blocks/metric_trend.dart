import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import 'package:starter/shared/theme/brand_tokens.dart';

/// Which way a change reads as good news (APP-BLOCKS.md "MetricTrend").
enum AppTrendGood {
  /// Rising is good, e.g. visitors.
  up,

  /// Falling is good, e.g. bounce rate.
  down,

  /// Neither direction is good or bad.
  neither,
}

/// How the change is written (APP-BLOCKS.md "MetricTrend").
enum AppTrendFormat {
  /// Scales by 100 and appends `%`: `+12%`.
  percent,

  /// The raw value with ` points`: `−2.8 points`.
  points,

  /// The raw value with group separators: `+1,234`.
  number,
}

/// Which way a metric moved, and whether that's good (APP-BLOCKS.md
/// "MetricTrend").
///
/// The arrow follows the direction, the color follows the meaning — a
/// falling bounce rate is green, a rising load time is red — and the words
/// always carry a sign, so color is never the only signal. Number and
/// percent strings are data composed here in a fixed `en_US` format so the
/// value never changes shape between renders; the zero-change words, when
/// wanted, come from [noChangeLabel].
class AppMetricTrend extends StatelessWidget {
  const AppMetricTrend({
    required this.change,
    this.good = AppTrendGood.up,
    this.format = AppTrendFormat.percent,
    this.comparison,
    this.noChangeLabel,
    super.key,
  });

  /// The change as a fraction: `0.12` means +12%.
  final double change;

  /// Which direction is good news; [AppTrendGood.neither] reads muted.
  final AppTrendGood good;

  final AppTrendFormat format;

  /// What the change is measured against, e.g. "vs last 30 days".
  final String? comparison;

  /// The words for no change, e.g. "No change". When change is zero and
  /// this is null, the formatted zero stands alone.
  final String? noChangeLabel;

  /// Whether the change is up, down, or flat.
  @visibleForTesting
  bool get isUp => change > 0;

  /// Whether the change is flat.
  @visibleForTesting
  bool get isFlat => change == 0;

  /// The resolved color role of the change: success when it moved the good
  /// way, destructive when it moved the wrong way, muted otherwise.
  @visibleForTesting
  AppTrendGood get meaning {
    if (isFlat || good == AppTrendGood.neither) {
      return AppTrendGood.neither;
    }
    final movedUp = isUp;
    return (movedUp && good == AppTrendGood.up) || (!movedUp && good == AppTrendGood.down)
        ? AppTrendGood.up
        : AppTrendGood.down;
  }

  /// The signed words for the change, always carrying a sign.
  @visibleForTesting
  String get signedText {
    if (isFlat && noChangeLabel != null) {
      return noChangeLabel!;
    }
    final sign = isFlat ? '' : (isUp ? '+' : '\u2212');
    final magnitude = switch (format) {
      AppTrendFormat.percent => _decimal.format(change.abs() * 100),
      AppTrendFormat.points => _decimal.format(change.abs()),
      AppTrendFormat.number => _whole.format(change.abs()),
    };
    final unit = switch (format) {
      AppTrendFormat.percent => '%',
      AppTrendFormat.points => ' points',
      AppTrendFormat.number => '',
    };
    return '$sign$magnitude$unit';
  }

  /// What screen readers hear: the direction spelled out, not a sign to
  /// decode (APP-BLOCKS.md MetricTrend) — "Up 12% vs last 30 days", "No
  /// change vs last 30 days".
  @visibleForTesting
  String get semanticsText {
    if (isFlat) {
      final word = noChangeLabel ?? 'No change';
      return comparison == null ? word : '$word ${comparison!.trim()}';
    }
    final direction = isUp ? 'Up' : 'Down';
    final magnitude = switch (format) {
      AppTrendFormat.percent => '${_decimal.format(change.abs() * 100)}%',
      AppTrendFormat.points => '${_decimal.format(change.abs())} points',
      AppTrendFormat.number => _whole.format(change.abs()),
    };
    return comparison == null
        ? '$direction $magnitude'
        : '$direction $magnitude ${comparison!.trim()}';
  }

  static final NumberFormat _decimal = NumberFormat.decimalPattern('en_US')
    ..maximumFractionDigits = 1;

  static final NumberFormat _whole = NumberFormat.decimalPattern('en_US')
    ..maximumFractionDigits = 0;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final brand = theme.brand;
    final color = switch (meaning) {
      AppTrendGood.up => brand.success,
      AppTrendGood.down => brand.destructive,
      AppTrendGood.neither => theme.colors.mutedForeground,
    };
    final icon = switch (change) {
      > 0 => FLucideIcons.arrowUpRight,
      < 0 => FLucideIcons.arrowDownRight,
      _ => FLucideIcons.minus,
    };
    return Semantics(
      label: semanticsText,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            signedText,
            style: theme.typography.body.xs.copyWith(color: color, fontWeight: FontWeight.w500),
          ),
          if (comparison != null) ...<Widget>[
            const SizedBox(width: 6),
            Text(
              comparison!,
              style: theme.typography.body.xs.copyWith(color: theme.colors.mutedForeground),
            ),
          ],
        ],
      ),
    );
  }
}
