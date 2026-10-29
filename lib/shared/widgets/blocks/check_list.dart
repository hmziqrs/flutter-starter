import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/brand_tokens.dart';
import 'package:starter/shared/widgets/brand/app_ring_marker.dart';

/// One row of an [AppCheckList]: a label and whether it holds.
typedef AppCheckItem = ({String label, bool checked});

/// A ticking checklist (BRAND.md s8, sign-up password rules): rows muted
/// until they are met.
///
/// A met row's marker fills in the success green — filled means done — and
/// its label reads in the normal text color. Unmet rows stay hollow and
/// muted. The words always carry the meaning; the ring only supports them.
class AppCheckList extends StatelessWidget {
  const AppCheckList({required this.items, super.key});

  final List<AppCheckItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Semantics(
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (var index = 0; index < items.length; index++) ...<Widget>[
            if (index > 0) const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: 5.5),
                  child: AppRingMarker(
                    filled: items[index].checked,
                    color: items[index].checked
                        ? theme.brand.success
                        : theme.colors.mutedForeground,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    items[index].label,
                    style: theme.typography.body.sm.copyWith(
                      color: items[index].checked
                          ? theme.colors.foreground
                          : theme.colors.mutedForeground,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
