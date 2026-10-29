import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/widgets/brand/app_ring_marker.dart';

/// One entry of an [AppToc].
class AppTocEntry {
  const AppTocEntry({required this.label, this.active = false});

  /// The section's name. Sentence case comes from the caller.
  final String label;

  /// Whether the reader is in this section right now; exactly one entry
  /// should carry it at a time.
  final bool active;
}

/// A table of contents (toc.svelte): one row per section, each opening with
/// the brand's hollow ring — the section you're reading takes the primary
/// ring and text, the rest stay in the border and muted colors. Numbered
/// documents use `01`-style orange digits instead of rings. Emphasis is
/// color only, so following the reader never moves anything.
///
/// Rows that overflow the label scroll sideways inside their own row; the
/// rail itself grows with its sections.
class AppToc extends StatelessWidget {
  const AppToc({
    required this.entries,
    required this.onSelected,
    this.numbered = false,
    this.semanticLabel,
    super.key,
  });

  /// The sections, in document order.
  final List<AppTocEntry> entries;

  /// Called with the tapped entry's index.
  final ValueChanged<int> onSelected;

  /// Number the rows `01`, `02`… in orange instead of the rings, for
  /// numbered documents (toc.svelte's `numbered`).
  final bool numbered;

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
          for (var index = 0; index < entries.length; index++) ...<Widget>[
            // The list spaces rows with gap-0.5 (2).
            if (index > 0) const SizedBox(height: 2),
            _TocRow(
              label: entries[index].label,
              active: entries[index].active,
              numbered: numbered,
              number: index + 1,
              onTap: () => onSelected(index),
            ),
          ],
        ],
      ),
    );
  }
}

class _TocRow extends StatefulWidget {
  const _TocRow({
    required this.label,
    required this.active,
    required this.onTap,
    this.numbered = false,
    this.number,
  });

  final String label;

  final bool active;

  final VoidCallback onTap;

  final bool numbered;

  final int? number;

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
            // The row's own air (toc.svelte: py-1), 8dp ring gap (gap-2).
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: <Widget>[
                if (widget.numbered)
                  // Numbered documents: min-w-6.5 (26) of 12dp orange
                  // tabular digits (toc.svelte).
                  SizedBox(
                    width: 26,
                    child: Text(
                      widget.number.toString().padLeft(2, '0'),
                      style: theme.typography.body.xs.copyWith(
                        color: theme.colors.primary,
                        fontWeight: FontWeight.w500,
                        height: 1,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: 5.5),
                    child: AppRingMarker(
                      // The current section's ring takes the primary; the
                      // others sit on the border color (toc.svelte).
                      color: widget.active ? theme.colors.primary : theme.colors.border,
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    // One weight everywhere: emphasis moves by color alone,
                    // so glyphs never reflow between sections.
                    style: theme.typography.body.sm.copyWith(
                      color: emphasized ? theme.colors.foreground : theme.colors.mutedForeground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
