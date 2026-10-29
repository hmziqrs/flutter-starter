import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/widgets/brand/app_ring_marker.dart';

/// The TL;DR box (BRAND.md s9): an outline rounded-xl with the primary at
/// 45% for its border, a small primary label beside a hollow ring, and the
/// short version in normal text.
///
/// Legal pages use the same box for "The short version". One color per
/// thing: the label and its ring carry the primary; the body stays in the
/// regular text colors.
class AppSummaryBox extends StatelessWidget {
  const AppSummaryBox({required this.label, required this.body, super.key});

  /// The small label, e.g. "TL;DR" or "The short version".
  final String label;

  /// The one-paragraph short version.
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: ShapeDecoration(
        color: Colors.transparent,
        shape: RoundedSuperellipseBorder(
          side: BorderSide(color: theme.colors.primary.withValues(alpha: 0.45)),
          borderRadius: theme.style.borderRadius.lg,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AppRingMarker(color: theme.colors.primary, size: 8),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  height: 1,
                  color: theme.colors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: theme.typography.body.sm.copyWith(color: theme.colors.foreground),
          ),
        ],
      ),
    );
  }
}
