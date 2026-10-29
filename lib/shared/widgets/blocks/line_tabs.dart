import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';

/// The brand line tabs (BRAND.md s8, app page header tabs): one row over a
/// 1px border; the active tab carries a 2px primary line under it, the rest
/// stay muted.
///
/// Feedback is color only — the underline and text color change, nothing
/// moves. The row scrolls sideways within itself when the labels overflow.
class AppLineTabs extends StatelessWidget {
  const AppLineTabs({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
    this.counts,
    this.semanticLabel,
    super.key,
  }) : assert(
         counts == null || counts.length == tabs.length,
         'counts must align with tabs.',
       );

  /// Tab labels, in order. Sentence case comes from the caller.
  final List<String> tabs;

  /// Optional per-tab counts, aligned with [tabs]; a null entry draws no
  /// chip. The chip is the svelte's foreground-at-8% pill in tabular
  /// figures.
  final List<int?>? counts;

  /// The zero-based active tab.
  final int selectedIndex;

  /// Called with the tapped tab's index.
  final ValueChanged<int> onSelected;

  /// What screen readers call the whole row, e.g. "Sections".
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Semantics(
      container: semanticLabel != null,
      label: semanticLabel,
      child: Container(
        // The row rides on the 1px bottom border (line-tabs.svelte's list
        // `border-b`); the triggers' own 2px underline draws inside, directly
        // above it.
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: theme.colors.border)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (var index = 0; index < tabs.length; index++) ...<Widget>[
                // The list spaces triggers with gap-6 (24); triggers carry
                // no horizontal padding, so the underline spans the words.
                if (index > 0) const SizedBox(width: 24),
                _LineTab(
                  label: tabs[index],
                  count: counts?[index],
                  selected: index == selectedIndex,
                  onTap: () => onSelected(index),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LineTab extends StatefulWidget {
  const _LineTab({
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final String label;

  final int? count;

  final bool selected;

  final VoidCallback onTap;

  @override
  State<_LineTab> createState() => _LineTabState();
}

class _LineTabState extends State<_LineTab> {
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
        selected: widget.selected,
        button: true,
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            // The trigger's own air: py-3 (12) over the text, with the
            // 2px underline at its foot and no horizontal padding — the
            // underline hugs the words.
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: widget.selected
                      ? theme.colors.primary
                      // Keeps the resting line transparent so the tab row's own
                      // 1px border is the only line under inactive tabs.
                      : (_focused
                            ? theme.colors.primary.withValues(alpha: 0.5)
                            : Colors.transparent),
                  width: 2,
                ),
              ),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Flexible(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      // One weight everywhere: the svelte trigger changes
                      // color and line only, so glyphs never reflow when
                      // the tab turns.
                      style: theme.typography.body.sm.copyWith(
                        color: widget.selected || _hovering
                            ? theme.colors.foreground
                            : theme.colors.mutedForeground,
                      ),
                    ),
                  ),
                  if (widget.count != null) ...<Widget>[
                    const SizedBox(width: 8),
                    Container(
                      // The count chip (line-tabs.svelte): foreground at 8%
                      // on a pill, tabular figures on a 12dp face.
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: ShapeDecoration(
                        color: theme.colors.foreground.withValues(alpha: 0.08),
                        shape: const StadiumBorder(),
                      ),
                      child: Text(
                        '${widget.count}',
                        style: theme.typography.body.xs.copyWith(
                          height: 1,
                          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
