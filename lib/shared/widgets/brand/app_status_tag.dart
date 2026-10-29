import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/brand_tokens.dart';
import 'package:starter/shared/widgets/brand/app_ring_marker.dart';

export 'package:starter/shared/theme/brand_tokens.dart' show AppStatusRole;

/// A soft status pill (BRAND.md s4, s8): the role color as a 10% fill (20% in
/// dark) with role-colored text, sentence case, small and radius-full.
///
/// Status is always soft; only orange is ever a solid fill behind text. The
/// neutral role is plain grey from the theme's secondary tokens. A live state
/// takes [showMarker], which draws the hollow ring marker before the label.
class AppStatusTag extends StatelessWidget {
  const AppStatusTag({
    required this.label,
    this.role = AppStatusRole.neutral,
    this.showMarker = false,
    super.key,
  });

  final String label;

  final AppStatusRole role;

  final bool showMarker;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final roleColor = theme.brand.roleColor(role);
    final fillOpacity = colors.brightness == Brightness.dark ? 0.20 : 0.10;
    final background = roleColor?.withValues(alpha: fillOpacity) ?? colors.secondary;
    final contentColor = roleColor ?? colors.secondaryForeground;
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: ShapeDecoration(color: background, shape: const StadiumBorder()),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (showMarker) ...<Widget>[
            AppRingMarker(color: contentColor, size: 7),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: theme.typography.body.xs.copyWith(
              color: contentColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
