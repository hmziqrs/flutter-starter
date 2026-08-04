import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// Renders a save-failure message as inline error text.
///
/// Used by settings sections to surface a persistence failure (typically
/// `common.notConnected`) with an error-colored `body.sm` style. The
/// [valueKey] is applied to the inner [Text] so tests and accessibility
/// audits can locate it by stable identity, matching the historical inline
/// save-error Texts in the settings pages.
class InlineSaveErrorText extends StatelessWidget {
  const InlineSaveErrorText({
    required this.message,
    required this.valueKey,
    super.key,
  });

  final String message;

  /// Stable key applied to the inner [Text] (e.g. `'settings-save-error'`).
  final String valueKey;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      key: ValueKey(valueKey),
      style: context.theme.typography.body.sm.copyWith(
        color: context.theme.colors.error,
      ),
    );
  }
}
