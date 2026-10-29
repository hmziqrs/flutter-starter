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
      // A floor, not a ceiling: at large text scales the pill grows with its
      // label instead of clipping it (20px is the rest-state recipe).
      constraints: const BoxConstraints(minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: ShapeDecoration(color: background, shape: const StadiumBorder()),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (showMarker) ...<Widget>[
            // The tag's marker is the smaller recipe: 7px ring at 1.5px
            // (tag.svelte's size-1.75 border-[1.5px]).
            AppRingMarker(color: contentColor, size: 7, borderWidth: 1.5),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.typography.body.xs.copyWith(
                color: contentColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
