import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';

/// One entry of an [AppToc].
class AppTocEntry {
  const AppTocEntry({required this.label, this.active = false});

  /// The section's name. Sentence case comes from the caller.
  final String label;

  /// Whether the reader is in this section right now; exactly one entry
  /// should carry it at a time.
  final bool active;
}

/// A table of contents (the reading kit's rail): one row per section with a
/// 2px start bar — the active section's bar takes the primary, the rest stay
/// transparent, so following the reader is color only and nothing moves.
///
/// Rows that overflow the label scroll sideways inside their own row; the
/// rail itself grows with its sections.
class AppToc extends StatelessWidget {
  const AppToc({
    required this.entries,
    required this.onSelected,
    this.semanticLabel,
    super.key,
  });

  /// The sections, in document order.
  final List<AppTocEntry> entries;

  /// Called with the tapped entry's index.
  final ValueChanged<int> onSelected;

  /// What screen readers call the rail, e.g. "On this page".
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: semanticLabel != null,
      label: semanticLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (var index = 0; index < entries.length; index++)
            _TocRow(
              label: entries[index].label,
              active: entries[index].active,
              onTap: () => onSelected(index),
            ),
        ],
      ),
    );
  }
}

class _TocRow extends StatefulWidget {
  const _TocRow({required this.label, required this.active, required this.onTap});

  final String label;

  final bool active;

  final VoidCallback onTap;

  @override
  State<_TocRow> createState() => _TocRowState();
}

class _TocRowState extends State<_TocRow> {
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
    final emphasized = widget.active || _hovering || _focused;
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
            widget.onTap();
            return null;
          },
        ),
      },
      child: Semantics(
        selected: widget.active,
        button: true,
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            // IntrinsicHeight bounds the row so the start bar can stretch to
            // the label's line height.
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // The 2px start bar; transparent when inactive so the row's
                  // rhythm never shifts.
                  Container(
                    width: 2,
                    color: widget.active ? theme.colors.primary : Colors.transparent,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.typography.body.sm.copyWith(
                        color: emphasized ? theme.colors.foreground : theme.colors.mutedForeground,
                        fontWeight: widget.active ? FontWeight.w500 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
