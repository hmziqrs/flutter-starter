import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/brand_tokens.dart';
import 'package:starter/shared/widgets/blocks/copy_button.dart';

/// One piece of a shell command, colored for scanning (BRAND.md s8 "Command
/// to copy"): the prompt and flags in the keyword color, the program in the
/// function color, quoted values as strings.
@immutable
class ShellToken {
  const ShellToken(this.text, this.kind);

  /// The prompt sigil (`$`) or a flag — the keyword color.
  static const keyword = 'keyword';

  /// The program to run — the function color.
  static const function = 'function';

  /// A quoted value — the string color.
  static const string = 'string';

  /// Arguments — the plain foreground.
  static const plain = 'plain';

  final String text;

  final String kind;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShellToken &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          kind == other.kind;

  @override
  int get hashCode => Object.hash(text, kind);

  @override
  String toString() => 'ShellToken($text, $kind)';
}

/// Splits a shell command into [ShellToken]s: the first word is the
/// program, `-`-prefixed words are flags, quoted words are strings. Shared
/// by the command bar and the command box, which color the same way.
List<ShellToken> tokenizeShellCommand(String command) {
  final tokens = <ShellToken>[];
  final pattern = RegExp(r'''(?:[^\s"']+|"[^"]*"|'[^']*')+''');
  for (final match in pattern.allMatches(command)) {
    final word = match.group(0)!;
    if (word.startsWith('-') && word.length > 1) {
      tokens.add(ShellToken(word, ShellToken.keyword));
    } else if (word.startsWith('"') || word.startsWith("'")) {
      tokens.add(ShellToken(word, ShellToken.string));
    } else if (tokens.isEmpty) {
      tokens.add(ShellToken(word, ShellToken.function));
    } else {
      tokens.add(ShellToken(word, ShellToken.plain));
    }
  }
  return tokens;
}

/// The brand command line (BRAND.md s8, command.svelte): the bare `$`
/// prompt and highlighted command, no container — for prose and lists where
/// the pill would shout.
///
/// The prompt can't be selected in the svelte, so a copy by hand gets only
/// the command; in Flutter the caller copies [command], never the sigil.
class AppCommandLine extends StatelessWidget {
  const AppCommandLine({required this.command, this.prompt = r'$', super.key});

  /// The command to show.
  final String command;

  /// The prompt sigil, `$` by default.
  final String prompt;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final brand = theme.brand;
    // The svelte line inherits the page's body size (16); the mono face is
    // the brand's JetBrains Mono either way.
    final base = TextStyle(
      fontFamily: 'JetBrains Mono',
      fontSize: 16,
      color: theme.colors.foreground,
    );
    return Text.rich(
      TextSpan(
        style: base,
        children: <InlineSpan>[
          TextSpan(
            text: prompt,
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
    );
  }
}

/// The brand command bar (BRAND.md s8): as wide as the command, in an
/// outline pill, with the `$` prompt in the primary, the program in the
/// function color, flags in the keyword color, and an outline copy button.
///
/// Commands people shouldn't paste as they are go out without a button:
/// pass [copyLabel] only when copying is the point.
class AppCommandBar extends StatelessWidget {
  const AppCommandBar({required this.command, this.prompt = r'$', this.copyLabel, super.key});

  /// The command to show, and the text the copy button puts on the
  /// clipboard.
  final String command;

  /// The prompt sigil, `$` by default.
  final String prompt;

  /// The copy button's semantics label; when set, the button shows.
  final String? copyLabel;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final brand = theme.brand;
    final base = TextStyle(
      fontFamily: 'JetBrains Mono',
      fontSize: 14,
      height: 1.4,
      color: theme.colors.foreground,
    );
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        // command-bar.svelte: pl-4.5; with the button `py-1.5 pr-1.5`, without
        // it `py-2.5 pr-4.5`, and a 16dp gap to the button (gap-4).
        padding: EdgeInsetsDirectional.only(
          start: 18,
          end: copyLabel == null ? 18 : 6,
          top: copyLabel == null ? 10 : 6,
          bottom: copyLabel == null ? 10 : 6,
        ),
        decoration: ShapeDecoration(
          color: Colors.transparent,
          shape: RoundedSuperellipseBorder(
            side: BorderSide(color: theme.colors.border, width: theme.style.borderWidth),
            borderRadius: theme.style.borderRadius.lg,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Flexible(
              child: Text.rich(
                TextSpan(
                  style: base,
                  children: <InlineSpan>[
                    TextSpan(
                      text: prompt,
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
            if (copyLabel != null) ...<Widget>[
              const SizedBox(width: 16),
              AppCopyButton(text: command, label: copyLabel!, style: AppCopyButtonStyle.outline),
            ],
          ],
        ),
      ),
    );
  }
}
