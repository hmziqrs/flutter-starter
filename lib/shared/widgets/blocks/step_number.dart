import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// A section's big orange number, `01`, `02`… (legal-section.svelte): two
/// digits, w500, in the primary under a thin line — the line is the
/// section's `border-t`, the air under it its `pt-5` plus the heading's
/// `mt-1`.
///
/// Numbers are data, not copy, so [index] is the one-based count and the
/// zero-padded digits are composed here, `min-w-7.5` wide (30dp) so `01`
/// through `09` align. Onest carries it — mono never renders headings,
/// labels or numbers.
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
        // border-t pt-5 (20) plus the heading's mt-1 (4).
        const SizedBox(height: 24),
        SizedBox(
          width: 30,
          child: Text(
            number,
            // The legal h2's number: text-[1.3rem] font-medium, tabular,
            // in the primary.
            style: theme.typography.body.lg.copyWith(
              color: theme.colors.primary,
              fontSize: 20.8,
              fontWeight: FontWeight.w500,
              height: 1,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}
