import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/theme/brand_tokens.dart';

/// An inline save failure: destructive text on a soft destructive fill, always
/// announced so the failure is never silent.
class InlineSaveErrorText extends StatelessWidget {
  const InlineSaveErrorText({
    required this.message,
    required this.valueKey,
    super.key,
  });

  final String message;

  final String valueKey;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final brand = context.theme.brand;
    return Container(
      key: ValueKey(valueKey),
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.md,
        vertical: context.spacing.sm,
      ),
      decoration: BoxDecoration(
        color: brand.destructive.withValues(
          alpha: switch (colors.brightness) {
            Brightness.dark => 0.2,
            Brightness.light => 0.1,
          },
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Semantics(
        container: true,
        liveRegion: true,
        child: Text(
          message,
          style: context.theme.typography.body.sm.copyWith(color: brand.destructive),
        ),
      ),
    );
  }
}
