import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// Which mark an [AppEyebrow] carries before its words (eyebrow.svelte).
enum AppEyebrowVariant {
  /// A 20dp numbered ring in the primary — the default.
  ring,

  /// A short 32×1 primary rule; the words stay muted.
  rule,

  /// One 2×12 tick per step, filled up to the current one.
  count,
}

/// The brand eyebrow (BRAND.md s8, eyebrow.svelte): a 13-scale label above a
/// title, with a small mark on the left — a numbered ring by default, a
/// short rule, or a run of ticks.
///
/// Sentence case only — the text renders exactly as given, never
/// uppercase-spaced. The mark and (except for the rule variant) the words
/// carry the primary; one color per thing.
class AppEyebrow extends StatelessWidget {
  const AppEyebrow(
    this.text, {
    this.variant = AppEyebrowVariant.ring,
    this.index = 1,
    this.total = 4,
    super.key,
  });

  /// The eyebrow's words, e.g. "Where the work goes".
  final String text;

  final AppEyebrowVariant variant;

  /// The one-based number in the ring, or the filled tick count.
  final int index;

  /// The total tick count for [AppEyebrowVariant.count].
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    const lineHeight = 20.0;
    final textStyle = theme.typography.body.sm.copyWith(
      // The svelte label is 13dp (text-[0.8125rem]) font-medium. The line box
      // is pinned to an even 20dp so every mark centers on whole pixels.
      fontSize: 13,
      height: lineHeight / 13,
      color: variant == AppEyebrowVariant.rule
          ? theme.colors.mutedForeground
          : theme.colors.primary,
      fontWeight: FontWeight.w500,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        switch (variant) {
          AppEyebrowVariant.ring => Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              shape: CircleBorder(
                side: BorderSide(color: theme.colors.primary, width: theme.style.borderWidth),
              ),
            ),
            child: Text(
              '$index',
              // 11dp digits inside the ring (text-[0.6875rem] tabular).
              style: textStyle.copyWith(
                fontSize: 11,
                height: 1,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          // A 32x1 rule, aligned 9dp under the pinned 20dp line-box top —
          // centered math ((20-1)/2) would land it on a half pixel and paint
          // two 50%-alpha rows instead of one crisp one. The Align keeps the
          // mark's constraints loose (a bare Padding under the tight line box
          // would force the remainder's height onto the 1px rule).
          AppEyebrowVariant.rule => SizedBox(
            width: 32,
            height: lineHeight,
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 9),
                child: Container(width: 32, height: 1, color: theme.colors.primary),
              ),
            ),
          ),
          AppEyebrowVariant.count => Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (var tick = 0; tick < total; tick++) ...<Widget>[
                if (tick > 0) const SizedBox(width: 4),
                Container(
                  width: 2,
                  height: 12,
                  decoration: ShapeDecoration(
                    color: tick < index ? theme.colors.primary : theme.colors.border,
                    shape: const StadiumBorder(),
                  ),
                ),
              ],
            ],
          ),
        },
        const SizedBox(width: 12),
        Text(text, style: textStyle),
      ],
    );
  }
}
