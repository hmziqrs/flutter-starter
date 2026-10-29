import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/widgets/brand/app_ring_marker.dart';

/// One topic chip: its label and the one color its category keeps
/// everywhere (BRAND.md s4). Pass a color from the theme's brand palette
/// (`context.theme.brand.teal`, for instance) and the chip opens with that
/// color's ring marker; leave `tone` null for a plain chip.
typedef AppTopicChip = ({String label, Color? tone});

/// The brand topic chips (topic-chips.svelte, blog index): 32dp outline
/// pills whose category color lives on a small ring marker.
///
/// The picked chip is drawn in the text color with a text-colored border
/// (`border-foreground text-foreground`) — the marker carries the color,
/// the fill never changes. Feedback is color only: hover warms the words to
/// the foreground, focus draws the primary ring, nothing moves.
class AppTopicChips extends StatelessWidget {
  const AppTopicChips({
    required this.chips,
    this.selectedIndex,
    this.onSelected,
    super.key,
  });

  final List<AppTopicChip> chips;

  /// The picked chip's index, when they filter.
  final int? selectedIndex;

  /// Called with the tapped chip's index; omit for a quiet row that only
  /// shows the topics.
  final ValueChanged<int>? onSelected;

  @override
  Widget build(BuildContext context) {
    // The row wraps with gap-1.5 (6).
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: <Widget>[
        for (var index = 0; index < chips.length; index++)
          _TopicChipView(
            chip: chips[index],
            selected: onSelected != null && index == selectedIndex,
            interactive: onSelected != null,
            onTap: onSelected == null ? null : () => onSelected!(index),
          ),
      ],
    );
  }
}

class _TopicChipView extends StatefulWidget {
  const _TopicChipView({
    required this.chip,
    required this.selected,
    required this.interactive,
    this.onTap,
  });

  final AppTopicChip chip;

  final bool selected;

  final bool interactive;

  final VoidCallback? onTap;

  @override
  State<_TopicChipView> createState() => _TopicChipViewState();
}

class _TopicChipViewState extends State<_TopicChipView> {
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
    final interactive = widget.interactive;
    final hovering = _hovering && interactive;
    final selected = widget.selected;
    return FocusableActionDetector(
      focusNode: interactive ? _focusNode : null,
      mouseCursor: interactive ? SystemMouseCursors.click : MouseCursor.defer,
      onShowHoverHighlight: interactive ? (hovering) => setState(() => _hovering = hovering) : null,
      onShowFocusHighlight: interactive ? (focused) => setState(() => _focused = focused) : null,
      shortcuts: interactive
          ? const <ShortcutActivator, Intent>{
              SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
              SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
            }
          : null,
      actions: interactive
          ? <Type, Action<Intent>>{
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (_) {
                  widget.onTap?.call();
                  return null;
                },
              ),
            }
          : null,
      child: Semantics(
        button: interactive,
        selected: selected,
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            // The chip: h-8 with a 1px outline and px-3
            // (topic-chips.svelte).
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: ShapeDecoration(
              shape: StadiumBorder(
                side: BorderSide(
                  // The picked chip's border turns the text color
                  // (aria-pressed:border-foreground); focus draws the
                  // primary ring at half strength.
                  color: _focused
                      ? theme.colors.primary.withValues(alpha: 0.5)
                      : selected
                      ? theme.colors.foreground
                      // The resting border is the theme's hairline.
                      : theme.colors.border,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (widget.chip.tone != null) ...<Widget>[
                  // The category's color lives on the chip's marker:
                  // size-1.75 (7) with a 1.5px ring in the tone.
                  AppRingMarker(color: widget.chip.tone, size: 7, borderWidth: 1.5),
                  // gap-2 between marker and words.
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.chip.label,
                  // text-[0.8125rem] font-medium; the words warm to the
                  // foreground on hover and when picked.
                  style: theme.typography.body.sm.copyWith(
                    color: selected || hovering
                        ? theme.colors.foreground
                        : theme.colors.mutedForeground,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
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
