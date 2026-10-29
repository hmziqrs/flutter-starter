import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// A section's big orange number, `01`, `02`… (BRAND.md s8, privacy/legal
/// pattern): two digits, w500, in the primary with a thin line above.
///
/// Numbers are data, not copy, so [index] is the one-based count and the
/// zero-padded digits are composed here. Onest carries it — mono never
/// renders headings, labels or numbers.
class AppStepNumber extends StatelessWidget {
  const AppStepNumber({required this.index, super.key});

  /// The one-based number to draw, zero-padded to two digits.
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final number = index.clamp(0, 99).toString().padLeft(2, '0');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(height: 1, color: theme.colors.border),
        const SizedBox(height: 12),
        Text(
          number,
          style: theme.typography.body.md.copyWith(
            color: theme.colors.primary,
            fontWeight: FontWeight.w500,
            height: 1,
          ),
        ),
      ],
    );
  }
}
