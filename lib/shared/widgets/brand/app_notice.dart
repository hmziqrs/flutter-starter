import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/brand_tokens.dart';

export 'package:starter/shared/theme/brand_tokens.dart' show AppStatusRole;

/// A quiet note (BRAND.md s9 "Notice"): a thin line in the note color, the
/// role's icon, and title and body in the normal text colors.
///
/// Transparent fill, no tinted box, no colored paragraphs. The icon mapping
/// follows BRAND.md s6: info, success, warning, error.
class AppNotice extends StatelessWidget {
  const AppNotice({
    required this.title,
    this.body,
    this.role = AppStatusRole.info,
    super.key,
  });

  final String title;

  final String? body;

  final AppStatusRole role;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final roleColor = theme.brand.roleColor(role) ?? theme.colors.mutedForeground;
    final icon = switch (role) {
      AppStatusRole.success => FLucideIcons.circleCheck,
      AppStatusRole.warning => FLucideIcons.triangleAlert,
      AppStatusRole.destructive => FLucideIcons.octagonAlert,
      AppStatusRole.info || AppStatusRole.neutral => FLucideIcons.info,
    };
    return Semantics(
      container: true,
      child: Container(
        width: double.infinity,
        // The brand alert's px-4 py-3 (APP-BLOCKS.md notice recipe).
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: ShapeDecoration(
          color: Colors.transparent,
          shape: RoundedSuperellipseBorder(
            side: BorderSide(color: roleColor.withValues(alpha: 0.4)),
            borderRadius: theme.style.borderRadius.md,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              // The brand alert nudges the icon 2px down to sit on the title.
              padding: const EdgeInsetsDirectional.only(top: 2),
              child: Icon(icon, size: 16, color: roleColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    title,
                    style: theme.typography.body.sm.copyWith(
                      color: theme.colors.foreground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (body != null) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      body!,
                      style: theme.typography.body.sm.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
