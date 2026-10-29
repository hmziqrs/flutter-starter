import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/widgets/brand/app_ring_marker.dart';

/// A quiet note where content would be (empty-note.svelte): one muted
/// sentence that opens with a primary ring, with air above and below.
///
/// For the moment a list, section or feed has nothing to show. It is a
/// note, not a state block with actions — the page draws anything the
/// reader can do about it.
class AppEmptyNote extends StatelessWidget {
  const AppEmptyNote(
    this.message, {
    this.padding = const EdgeInsets.symmetric(vertical: 32),
    super.key,
  });

  final String message;

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Padding(
      padding: padding,
      child: Row(
        children: <Widget>[
          // The ring takes the primary; the words stay muted.
          AppRingMarker(color: theme.colors.primary),
          // gap-2.5 (10).
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.typography.body.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
