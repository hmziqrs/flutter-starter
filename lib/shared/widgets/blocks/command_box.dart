import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/brand_tokens.dart';
import 'package:starter/shared/widgets/blocks/command_bar.dart';
import 'package:starter/shared/widgets/blocks/copy_button.dart';

/// The brand command box (BRAND.md s8, command-box.svelte): a smaller
/// command than the bar — one line of 13dp mono in a tight rounded-md pill,
/// with the `$` prompt in the primary, the program in the function color,
/// flags in the keyword color, and an icon copy button at its right.
///
/// It is the per-step variant of [AppCommandBar]: the pill for a command
/// inside a list of steps. Commands people shouldn't paste as they are go
/// out without a button: pass [copyLabel] only when copying is the point.
class AppCommandBox extends StatelessWidget {
  const AppCommandBox({
    required this.command,
    this.copyLabel,
    this.copiedLabel,
    this.prompt = r'$',
    super.key,
  });

  /// The command to show, and the text the copy button puts on the
  /// clipboard.
  final String command;

  /// The copy button's semantics label; when set, the icon button shows.
  final String? copyLabel;

  /// The copy button's semantics label once copied, e.g. "Copied".
  final String? copiedLabel;

  /// The prompt sigil, `$` by default.
  final String prompt;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final brand = theme.brand;
    final base = TextStyle(
      fontFamily: 'JetBrains Mono',
      fontSize: 13,
      height: 1.7,
      color: theme.colors.foreground,
    );
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        // The pill grows with its command and stops at 52rem
        // (command-box.svelte: max-w-[52rem]).
        constraints: const BoxConstraints(maxWidth: 832),
        child: Container(
          // command-box.svelte: rounded-md border py-1 pr-1 pl-3.5, gap-2.
          padding: const EdgeInsetsDirectional.only(start: 14, end: 4, top: 4, bottom: 4),
          decoration: ShapeDecoration(
            color: Colors.transparent,
            shape: RoundedSuperellipseBorder(
              side: BorderSide(color: theme.colors.border, width: theme.style.borderWidth),
              borderRadius: theme.style.borderRadius.sm,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Flexible(
                child: Padding(
                  // The command line keeps its own 4dp of air inside the
                  // pill (the svelte inner py-1).
                  padding: const EdgeInsetsDirectional.only(top: 4, bottom: 4),
                  child: Text.rich(
                    TextSpan(
                      style: base,
                      children: <InlineSpan>[
                        TextSpan(
                          text: prompt,
                          // The prompt can't be selected in the svelte, so a
                          // hand copy gets only the command; it reads in the
                          // primary either way.
                          style: TextStyle(color: theme.colors.primary),
                        ),
                        const TextSpan(text: ' '),
                        for (final token in tokenizeShellCommand(command))
                          TextSpan(
                            text: '${token.text} ',
                            style: TextStyle(
                              color: switch (token.kind) {
                                ShellToken.keyword => theme.colors.primary,
                                ShellToken.function => brand.info,
                                ShellToken.string => brand.success,
                                _ => theme.colors.foreground,
                              },
                            ),
                          ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (copyLabel != null) ...<Widget>[
                const SizedBox(width: 8),
                // The icon copy button (CopyButton with no label in the
                // svelte), so the pill stays one step tall.
                AppCopyButton(text: command, label: copyLabel!, copiedLabel: copiedLabel),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
