import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/brand_tokens.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;

/// What one line of an [AppTerminalWindow] or [AppTerminalLines] shows.
enum AppTerminalLineKind {
  /// A command the reader runs — `$ command`.
  command,

  /// A quiet note — `# note` in grey.
  note,

  /// A step with what it answered — `▸ step › answer`.
  step,

  /// A finished result — `✓ result`.
  result,

  /// A key and its value — `key: value` with the key in grey.
  keyValue,
}

/// One line of a terminal.
class AppTerminalLine {
  const AppTerminalLine(this.text, this.kind, {this.answer});

  const AppTerminalLine.command(String text) : this(text, AppTerminalLineKind.command);

  const AppTerminalLine.note(String text) : this(text, AppTerminalLineKind.note);

  /// A step, with the answer its `›` points at, e.g. `Building › 3 crates`.
  const AppTerminalLine.step(String text, {String? answer})
    : this(text, AppTerminalLineKind.step, answer: answer);

  const AppTerminalLine.result(String text) : this(text, AppTerminalLineKind.result);

  /// A key and its value, e.g. `Binary: target/debug/freeoxide`.
  const AppTerminalLine.keyValue(String key, String value)
    : this(key, AppTerminalLineKind.keyValue, answer: value);

  final String text;

  final AppTerminalLineKind kind;

  /// The step's answer after the `›`, or the key's value after the `:`.
  final String? answer;
}

/// The brand terminal window (BRAND.md s8): always dark, even on a light
/// page, with a 40dp title bar carrying a terminal icon, and mono lines —
/// `$ command`, `# note` in grey, `▸ step › answer`, `✓ result`,
/// `key: value`.
///
/// The window re-themes itself with the generated dark theme, so a light
/// page gets its dark island and the lines stay readable in both modes.
/// The raw generated theme keeps a neutral grey primary, so the `$` prompt
/// and `▸` step marker draw in the brand's oxide directly (BRAND.md s8:
/// "$ prompt in orange").
class AppTerminalWindow extends StatelessWidget {
  const AppTerminalWindow({required this.title, required this.lines, this.actions, super.key});

  /// The title bar's label, e.g. a file or session name. The bar reads in
  /// the page font like the svelte title bar; mono stays in the lines.
  final String title;

  final List<AppTerminalLine> lines;

  /// Small icon buttons at the title bar's end, e.g. a replay button
  /// (terminal-window.svelte's `actions` snippet).
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return FTheme(
      data: generated.darkTheme,
      child: _TerminalBody(title: title, lines: lines, actions: actions),
    );
  }
}

class _TerminalBody extends StatelessWidget {
  const _TerminalBody({required this.title, required this.lines, required this.actions});

  final String title;

  final List<AppTerminalLine> lines;

  final List<Widget>? actions;

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
            // Title-bar air (terminal-window.svelte: pl-3.5 pr-1.5).
            padding: const EdgeInsetsDirectional.only(start: 14, end: 6),
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
                    // The bar reads in the page font at the svelte title
                    // bar's 13 (text-[0.8125rem] text-muted-foreground);
                    // mono stays in the lines below.
                    style: dark.typography.body.sm.copyWith(
                      fontSize: 13,
                      color: dark.colors.mutedForeground,
                    ),
                  ),
                ),
                if (actions case final actions?)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    // The actions span sits at the bar's end, its buttons
                    // separated by half a gap (ml-auto flex gap-0.5).
                    children: <Widget>[
                      for (var index = 0; index < actions.length; index++) ...<Widget>[
                        if (index > 0) const SizedBox(width: 2),
                        actions[index],
                      ],
                    ],
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: ConstrainedBox(
              // The body keeps the reference's 200dp floor (terminal-body
              // .svelte: min-h-50), so a two-line session still sits like a
              // terminal.
              constraints: const BoxConstraints(minHeight: 200),
              child: AppTerminalLines(lines: lines),
            ),
          ),
        ],
      ),
    );
  }
}

/// Terminal lines on their own, without the window: the bare mono run a
/// page drops between paragraphs (terminal.stories' "Lines"). Unlike the
/// window, these read in the ambient theme — the window is the dark island,
/// not the lines.
class AppTerminalLines extends StatelessWidget {
  const AppTerminalLines({required this.lines, super.key});

  final List<AppTerminalLine> lines;

  @override
  Widget build(BuildContext context) {
    return Column(
      // The body's 1.9 leading already sets the rhythm; no extra air lands
      // between lines (terminal-body.svelte: leading-[1.9], nothing else).
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final line in lines) _TerminalLineView(line: line),
      ],
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
            // A step's answer reads in the string role, behind a muted ›
            // (terminal-line.svelte: text-(--code-token-string)).
            if (line.answer case final answer?) ...<InlineSpan>[
              const TextSpan(text: ' '),
              TextSpan(
                text: '› ',
                style: TextStyle(color: theme.colors.mutedForeground),
              ),
              TextSpan(
                text: answer,
                style: TextStyle(color: brand.success),
              ),
            ],
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
      AppTerminalLineKind.keyValue => Text.rich(
        TextSpan(
          style: mono,
          children: <InlineSpan>[
            TextSpan(
              text: '${line.text}: ',
              style: TextStyle(color: theme.colors.mutedForeground),
            ),
            TextSpan(text: line.answer ?? ''),
          ],
        ),
      ),
    };
  }
}
