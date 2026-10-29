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
/// filtered command list, grouped under their section headings, with the
/// footer action row naming the first result. Sheets and dialogs host it;
/// the widget itself stays a plain box so the host owns the presentation.
///
/// Matching is a case-insensitive contains over label and section — the
/// palette filters, it does not rank. Results past [maxVisible] collapse
/// into one muted line so the panel never scrolls inside a scrolling page.
class AppCommandPalette extends StatefulWidget {
  const AppCommandPalette({
    required this.commands,
    this.queryHint = 'Search commands',
    this.emptyLabel = 'No matching commands',
    this.primaryLabel = 'Open',
    this.maxVisible = 6,
    this.onSelected,
    super.key,
  });

  final List<AppCommand> commands;

  /// The query line's hint.
  final String queryHint;

  /// What shows when nothing matches.
  final String emptyLabel;

  /// The footer action's word for the first result, e.g. "Open" — the
  /// svelte footer's `current.primary ?? "Open"`.
  final String primaryLabel;

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
          // The palette shell is rounded-2xl (18dp) in the svelte.
          borderRadius: theme.style.borderRadius.xl,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            // The query row's air (command-palette.svelte: h-14 px-5).
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
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
            // Grouped results: a heading wherever the section changes, as
            // the svelte renders one Command.Group per group with its
            // GroupHeading.
            for (var index = 0; index < visible.length; index++) ...<Widget>[
              if (_sectionHeading(visible, index) case final heading?)
                Padding(
                  // GroupHeading: px-3 pt-2 pb-1.5 text-xs font-medium
                  // text-muted-foreground.
                  padding: const EdgeInsetsDirectional.only(
                    start: 12,
                    end: 12,
                    top: 8,
                    bottom: 6,
                  ),
                  child: Text(
                    heading,
                    style: theme.typography.body.xs.copyWith(
                      color: theme.colors.mutedForeground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              _CommandRow(command: visible.elementAt(index), onPicked: _pick),
            ],
            if (overflow > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  '$overflow more — narrow the query',
                  style: theme.typography.body.xs.copyWith(color: theme.colors.mutedForeground),
                ),
              ),
            // The footer action row (h-11 border-t px-4 text-xs): the
            // current result's section as context on the left, the primary
            // action with its return key on the right. It runs the first
            // visible command — this panel has no keyboard highlight; the
            // host owns focus.
            Container(
              height: 44,
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: theme.colors.border)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      visible.first.section ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.typography.body.xs.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _pick(visible.first),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            widget.primaryLabel,
                            style: theme.typography.body.xs.copyWith(
                              color: theme.colors.foreground,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colors.foreground.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              FLucideIcons.cornerDownLeft,
                              size: 12,
                              color: theme.colors.mutedForeground,
                              semanticLabel: widget.primaryLabel,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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

  /// The heading for the row at [index], or null when the row continues the
  /// previous row's section (or has none).
  String? _sectionHeading(Iterable<AppCommand> visible, int index) {
    final section = visible.elementAt(index).section;
    if (section == null) {
      return null;
    }
    if (index == 0) {
      return section;
    }
    return visible.elementAt(index - 1).section == section ? null : section;
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
          // The highlighted row carries the foreground at 8% wash
          // (command-palette.svelte: data-selected:bg-foreground/8), 44dp
          // tall (h-11).
          color: highlighted ? theme.colors.foreground.withValues(alpha: 0.08) : null,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: <Widget>[
              if (widget.command.icon != null) ...<Widget>[
                Container(
                  // The icon sits in a 28dp outline tile (size-7 rounded-md
                  // border); a highlighted row draws its border and icon in
                  // the primary at half strength.
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: ShapeDecoration(
                    shape: RoundedSuperellipseBorder(
                      side: BorderSide(
                        color: highlighted
                            ? theme.colors.primary.withValues(alpha: 0.5)
                            : theme.colors.border,
                      ),
                      borderRadius: theme.style.borderRadius.sm,
                    ),
                  ),
                  child: Icon(
                    widget.command.icon,
                    size: 16,
                    color: highlighted ? theme.colors.primary : theme.colors.mutedForeground,
                  ),
                ),
                const SizedBox(width: 12),
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
                const SizedBox(width: 12),
                Container(
                  // The shortcut renders as a kbd chip: foreground at 8% on a
                  // small mono rounded rect (Kbd class="bg-foreground/8").
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colors.foreground.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.command.shortcutLabel!,
                    style: theme.typography.body.xs.copyWith(
                      color: theme.colors.mutedForeground,
                      fontFamily: 'JetBrains Mono',
                    ),
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
