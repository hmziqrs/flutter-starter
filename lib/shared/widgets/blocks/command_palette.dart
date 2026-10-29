import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';

/// One entry of an [AppCommandPalette].
class AppCommand {
  const AppCommand({
    required this.label,
    required this.onSelected,
    this.section,
    this.icon,
    this.shortcutLabel,
  });

  /// What the command does. Sentence case comes from the caller.
  final String label;

  /// An optional grouping word, e.g. "View" — matched by the query too.
  final String? section;

  /// The command's icon; from [FLucideIcons].
  final IconData? icon;

  /// The shortcut to show, e.g. "⌘K" — display only; the palette does not
  /// register it.
  final String? shortcutLabel;

  /// Runs the command.
  final VoidCallback onSelected;
}

/// The command palette as an embeddable panel: a query line over the
/// filtered command list. Sheets and dialogs host it; the widget itself
/// stays a plain box so the host owns the presentation.
///
/// Matching is a case-insensitive contains over label and section — the
/// palette filters, it does not rank. Results past [maxVisible] collapse
/// into one muted line so the panel never scrolls inside a scrolling page.
class AppCommandPalette extends StatefulWidget {
  const AppCommandPalette({
    required this.commands,
    this.queryHint = 'Search commands',
    this.emptyLabel = 'No matching commands',
    this.maxVisible = 6,
    this.onSelected,
    super.key,
  });

  final List<AppCommand> commands;

  /// The query line's hint.
  final String queryHint;

  /// What shows when nothing matches.
  final String emptyLabel;

  /// How many results render before the rest collapse into a count.
  final int maxVisible;

  /// Called after a command's own [AppCommand.onSelected] runs — the hook a
  /// host uses to dismiss itself.
  final VoidCallback? onSelected;

  @override
  State<AppCommandPalette> createState() => _AppCommandPaletteState();
}

class _AppCommandPaletteState extends State<AppCommandPalette> {
  String _query = '';

  List<AppCommand> get _matches {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return widget.commands;
    }
    return <AppCommand>[
      for (final command in widget.commands)
        if (command.label.toLowerCase().contains(query) ||
            (command.section?.toLowerCase().contains(query) ?? false))
          command,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final matches = _matches;
    final visible = matches.take(widget.maxVisible);
    final overflow = matches.length - visible.length;
    return Container(
      decoration: ShapeDecoration(
        color: Colors.transparent,
        shape: RoundedSuperellipseBorder(
          side: BorderSide(color: theme.colors.border, width: theme.style.borderWidth),
          borderRadius: theme.style.borderRadius.lg,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: FTextField(
              control: .managed(onChange: (value) => setState(() => _query = value.text)),
              hint: widget.queryHint,
              keyboardType: TextInputType.text,
              autocorrect: false,
              enableSuggestions: false,
              // Brand text field: a line, no fill (search_field.dart's rule).
              style: .delta(color: .delta([.base(null), .variants(null)])),
              prefixBuilder: (context, style, variants) =>
                  Icon(FLucideIcons.search, size: 16, color: theme.colors.mutedForeground),
            ),
          ),
          Container(height: 1, color: theme.colors.border),
          if (matches.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Text(
                widget.emptyLabel,
                style: theme.typography.body.sm.copyWith(color: theme.colors.mutedForeground),
              ),
            )
          else ...<Widget>[
            for (final command in visible) _CommandRow(command: command, onPicked: _pick),
            if (overflow > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  '$overflow more — narrow the query',
                  style: theme.typography.body.xs.copyWith(color: theme.colors.mutedForeground),
                ),
              ),
          ],
        ],
      ),
    );
  }

  void _pick(AppCommand command) {
    command.onSelected();
    widget.onSelected?.call();
  }
}

/// One tappable command row: icon, label, shortcut; hover and focus change
/// color only (BRAND.md s8).
class _CommandRow extends StatefulWidget {
  const _CommandRow({required this.command, required this.onPicked});

  final AppCommand command;

  final ValueChanged<AppCommand> onPicked;

  @override
  State<_CommandRow> createState() => _CommandRowState();
}

class _CommandRowState extends State<_CommandRow> {
  bool _hovering = false;
  bool _focused = false;
  late final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final highlighted = _hovering || _focused;
    return FocusableActionDetector(
      focusNode: _focusNode,
      mouseCursor: SystemMouseCursors.click,
      onShowHoverHighlight: (hovering) => setState(() => _hovering = hovering),
      onShowFocusHighlight: (focused) => setState(() => _focused = focused),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onPicked(widget.command);
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTap: () => widget.onPicked(widget.command),
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: highlighted ? theme.colors.muted : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: <Widget>[
              if (widget.command.icon != null) ...<Widget>[
                Icon(
                  widget.command.icon,
                  size: 16,
                  color: theme.colors.mutedForeground,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  widget.command.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.typography.body.sm.copyWith(color: theme.colors.foreground),
                ),
              ),
              if (widget.command.shortcutLabel != null) ...<Widget>[
                const SizedBox(width: 8),
                Text(
                  widget.command.shortcutLabel!,
                  style: theme.typography.body.xs.copyWith(
                    color: theme.colors.mutedForeground,
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
