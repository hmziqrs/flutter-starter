import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/brand_tokens.dart';

/// An inline save failure (BRAND.md s4 "status is always soft", s11 "errors
/// say what went wrong and how to fix it"): destructive text with the
/// destructive role's icon on the role's soft fill — 10% in light, 20% in
/// dark — never a solid red panel, and always announced so the failure is
/// never silent.
class InlineSaveErrorText extends StatelessWidget {
  const InlineSaveErrorText({
    required this.message,
    required this.valueKey,
    super.key,
  });

  /// What went wrong, and the way out.
  final String message;

  /// Names the strip's [ValueKey] for tests.
  final String valueKey;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final destructive = theme.brand.destructive;
    return Container(
      key: ValueKey(valueKey),
      width: double.infinity,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: destructive.withValues(
          alpha: theme.colors.brightness == Brightness.dark ? 0.20 : 0.10,
        ),
      ),
      child: Semantics(
        container: true,
        liveRegion: true,
        child: Row(
          children: [
            Icon(FLucideIcons.octagonAlert, size: 14, color: destructive),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: theme.typography.body.sm.copyWith(color: destructive),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
