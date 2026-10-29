import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// A quiet note where content would be (BRAND.md s9, content pieces): one
/// muted sentence, centered, no box.
///
/// For the moment a list, section or feed has nothing to show. It is a
/// note, not a state block with actions — the page draws anything the
/// reader can do about it.
class AppEmptyNote extends StatelessWidget {
  const AppEmptyNote(
    this.message, {
    this.padding = const EdgeInsets.symmetric(vertical: 24),
    super.key,
  });

  final String message;

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Padding(
      padding: padding,
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: theme.typography.body.xs.copyWith(color: theme.colors.mutedForeground),
        ),
      ),
    );
  }
}
