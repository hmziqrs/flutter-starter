import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/brand_tokens.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;

/// What one line of an [AppTerminalWindow] shows.
enum AppTerminalLineKind {
  /// A command the reader runs — `$ command`.
  command,

  /// A quiet note — `# note` in grey.
  note,

  /// A step with what it answered — `▸ step › answer`.
  step,

  /// A finished result — `✓ result`.
  result,
}

/// One line of an [AppTerminalWindow].
class AppTerminalLine {
  const AppTerminalLine(this.text, this.kind);

  const AppTerminalLine.command(String text) : this(text, AppTerminalLineKind.command);

  const AppTerminalLine.note(String text) : this(text, AppTerminalLineKind.note);

  const AppTerminalLine.step(String text) : this(text, AppTerminalLineKind.step);

  const AppTerminalLine.result(String text) : this(text, AppTerminalLineKind.result);

  final String text;

  final AppTerminalLineKind kind;
}

/// The brand terminal window (BRAND.md s8): always dark, even on a light
/// page, with a 40dp title bar carrying a terminal icon, and mono lines —
/// `$ command`, `# note` in grey, `▸ step › answer`, `✓ result`.
///
/// The window re-themes itself with the generated dark theme, so a light
/// page gets its dark island and the lines stay readable in both modes.
/// The raw generated theme keeps a neutral grey primary, so the `$` prompt
/// and `▸` step marker draw in the brand's oxide directly (BRAND.md s8:
/// "$ prompt in orange").
class AppTerminalWindow extends StatelessWidget {
  const AppTerminalWindow({required this.title, required this.lines, super.key});

  /// The title bar's label, e.g. a file or session name. Machine names run
  /// in mono.
  final String title;

  final List<AppTerminalLine> lines;

  @override
  Widget build(BuildContext context) {
    return FTheme(
      data: generated.darkTheme,
      child: _TerminalBody(title: title, lines: lines),
    );
  }
}

class _TerminalBody extends StatelessWidget {
  const _TerminalBody({required this.title, required this.lines});

  final String title;

  final List<AppTerminalLine> lines;

  @override
  Widget build(BuildContext context) {
    final dark = context.theme;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: dark.colors.background,
        shape: RoundedSuperellipseBorder(
          side: BorderSide(color: dark.colors.border, width: dark.style.borderWidth),
          borderRadius: dark.style.borderRadius.lg,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: dark.colors.border)),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  FLucideIcons.squareTerminal,
                  size: 16,
                  color: dark.colors.mutedForeground,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 12,
                      color: dark.colors.mutedForeground,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (var index = 0; index < lines.length; index++) ...<Widget>[
                  if (index > 0) const SizedBox(height: 2),
                  _TerminalLineView(line: lines[index]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TerminalLineView extends StatelessWidget {
  const _TerminalLineView({required this.line});

  final AppTerminalLine line;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final brand = theme.brand;
    final mono = TextStyle(
      fontFamily: 'JetBrains Mono',
      fontSize: 13,
      height: 1.9,
      color: theme.colors.foreground,
    );
    return switch (line.kind) {
      AppTerminalLineKind.command => Text.rich(
        TextSpan(
          style: mono,
          children: <InlineSpan>[
            TextSpan(
              text: r'$ ',
              style: TextStyle(color: theme.brand.oxide),
            ),
            TextSpan(text: line.text),
          ],
        ),
      ),
      AppTerminalLineKind.note => Text.rich(
        TextSpan(
          style: mono,
          children: <InlineSpan>[
            TextSpan(
              text: '# ',
              style: TextStyle(color: theme.colors.mutedForeground),
            ),
            TextSpan(
              text: line.text,
              style: TextStyle(color: theme.colors.mutedForeground),
            ),
          ],
        ),
      ),
      AppTerminalLineKind.step => Text.rich(
        TextSpan(
          style: mono,
          children: <InlineSpan>[
            TextSpan(
              text: '▸ ',
              style: TextStyle(color: theme.brand.oxide),
            ),
            TextSpan(text: line.text),
          ],
        ),
      ),
      AppTerminalLineKind.result => Text.rich(
        TextSpan(
          style: mono,
          children: <InlineSpan>[
            TextSpan(
              text: '✓ ',
              style: TextStyle(color: brand.success),
            ),
            TextSpan(text: line.text),
          ],
        ),
      ),
    };
  }
}
