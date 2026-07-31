import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';

/// Severity of an in-flight action reflected by [BusyIndicator].
///
/// The severity only supplies a default accessibility label — the visual
/// primitive is the same ForUI spinner, so every async action looks identical.
enum BusySeverity {
  /// No busy state; the indicator renders nothing.
  none,

  /// A generic in-flight action (for example signing in or fetching data).
  active,

  /// A persisting action (for example saving a profile draft).
  saving,
}

/// A themed wrapper over ForUI's [FCircularProgress] (indeterminate) and
/// [FDeterminateProgress] (determinate) progress primitives.
///
/// Pass a [value] of `null` for an indeterminate spinner, or a fraction in
/// `0.0..1.0` for a determinate bar. Any non-null [value] is clamped to the
/// valid range so callers can never trip [FDeterminateProgress]'s assertion.
/// [severity] supplies a localized default [semanticsLabel]; pass an explicit
/// label to override it.
///
/// This is the single shared busy primitive — every async action (auth submit
/// states, profile save, ...) adopts it instead of forking a progress widget.
class BusyIndicator extends StatelessWidget {
  const BusyIndicator({
    this.value,
    this.semanticsLabel,
    this.severity = BusySeverity.active,
    this.size = FCircularProgressSizeVariant.md,
    super.key,
  });

  /// Determinate progress fraction.
  ///
  /// `null` renders an indeterminate [FCircularProgress]; any non-null value is
  /// clamped to `0.0..1.0` and rendered as a determinate [FDeterminateProgress].
  final double? value;

  /// Accessibility label forwarded to the ForUI primitive.
  ///
  /// Defaults to a severity-specific localized label (`common.loading` for
  /// [BusySeverity.active], `common.saving` for [BusySeverity.saving]).
  final String? semanticsLabel;

  /// Drives the default [semanticsLabel]. [BusySeverity.none] renders nothing.
  final BusySeverity severity;

  /// Size of the indeterminate [FCircularProgress].
  ///
  /// Ignored once a non-null [value] selects the determinate bar.
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
