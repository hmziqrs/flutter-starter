import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/widgets/blocks/code_lines.dart';
import 'package:starter/shared/widgets/blocks/copy_button.dart';

/// The brand code block (BRAND.md s8): an outline with no fill, an optional
/// 40dp header bar carrying the file label and a copy button, and the
/// source under it in JetBrains Mono 13 with the brand's code colors.
///
/// Shiki has no Flutter equivalent, so the highlighting is the small Dart
/// tokenizer in `code_lines.dart` mapped onto the same `--code-*` roles.
/// No copy button on code people only read: pass [copyLabel] to add one.
class AppCodeBlock extends StatelessWidget {
  const AppCodeBlock({required this.source, this.label, this.copyLabel, super.key});

  /// The code to show.
  final String source;

  /// The file label in the header bar, e.g. `main.dart`; omit for no bar.
  final String? label;

  /// The copy button's semantics label; when set, a copy button appears in
  /// the header bar. The block needs a [label] to carry it.
  final String? copyLabel;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    assert(
      copyLabel == null || label != null,
      'A copy button needs a header bar: pass label alongside copyLabel.',
    );
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: Colors.transparent,
        shape: RoundedSuperellipseBorder(
          side: BorderSide(color: theme.colors.border, width: theme.style.borderWidth),
          borderRadius: theme.style.borderRadius.lg,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (label != null)
            Container(
              height: 40,
              padding: const EdgeInsetsDirectional.only(start: 16, end: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: theme.colors.border)),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      label!,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        // File names run in mono, machine values only.
                        fontFamily: 'JetBrains Mono',
                        fontSize: 12,
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ),
                  if (copyLabel != null) AppCopyButton(text: source, label: copyLabel!),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: AppCodeLines(source: source),
          ),
        ],
      ),
    );
  }
}
