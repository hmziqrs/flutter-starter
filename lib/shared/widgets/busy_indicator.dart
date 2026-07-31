import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';

enum BusySeverity {
  none,

  active,

  saving,
}

class BusyIndicator extends StatelessWidget {
  const BusyIndicator({
    this.value,
    this.semanticsLabel,
    this.severity = BusySeverity.active,
    this.size = FCircularProgressSizeVariant.md,
    super.key,
  });

  final double? value;

  final String? semanticsLabel;

  final BusySeverity severity;

  final FCircularProgressSizeVariant size;

  @override
  Widget build(BuildContext context) {
    if (severity == BusySeverity.none) {
      return const SizedBox.shrink();
    }
    final label = semanticsLabel ?? _defaultLabel(context);
    final determinate = value;
    if (determinate == null) {
      return FCircularProgress(size: size, semanticsLabel: label);
    }
    return FDeterminateProgress(value: _clamp(determinate), semanticsLabel: label);
  }

  String _defaultLabel(BuildContext context) {
    final translations = context.t.common;
    return switch (severity) {
      BusySeverity.none => translations.loading,
      BusySeverity.active => translations.loading,
      BusySeverity.saving => translations.saving,
    };
  }

  static double _clamp(double value) {
    if (value < 0) return 0;
    if (value > 1) return 1;
    return value;
  }
}
