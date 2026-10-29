import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/widgets/brand/app_ring_marker.dart';

/// A list whose bullets are the brand's hollow ring markers (BRAND.md s7).
///
/// The svelte list draws every ring in the primary ("A list with orange
/// rings for bullets"); the ring stays hollow — a filled ring is reserved
/// for on, open, done or selected states elsewhere. Never a solid dot,
/// square or emoji.
class AppBullets extends StatelessWidget {
  const AppBullets({required this.items, super.key});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (var index = 0; index < items.length; index++) ...<Widget>[
          if (index > 0) const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                // Hangs the ring on the first text line, like the svelte
                // grid's baseline row.
                padding: const EdgeInsetsDirectional.only(top: 5.5),
                child: AppRingMarker(color: theme.colors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  items[index],
                  style: theme.typography.body.sm.copyWith(
                    color: theme.colors.foreground,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
