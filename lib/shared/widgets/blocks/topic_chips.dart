import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// One topic chip: its label and the one color its category keeps
/// everywhere (BRAND.md s4). Pass a color from the theme's brand palette
/// (`context.theme.brand.teal`, for instance) or leave `tone` null for the
/// plain grey tag.
typedef AppTopicChip = ({String label, Color? tone});

/// The brand topic chips (BRAND.md s8, blog index): soft tags in one color
/// per category, radius-full.
///
/// With [onSelected] they filter: the picked chip takes the selected look
/// (primary border at 60%, soft primary fill, primary text) and every chip
/// grows to the 32dp touch floor. Without it they are quiet 20dp tags.
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

  /// Called with the tapped chip's index; omit for non-interactive tags.
  final ValueChanged<int>? onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (var index = 0; index < chips.length; index++)
          _TopicChipView(
            chip: chips[index],
            selected: onSelected != null && index == selectedIndex,
            interactive: onSelected != null,
            isDark: context.theme.colors.brightness == Brightness.dark,
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
    required this.isDark,
    this.onTap,
  });

  final AppTopicChip chip;

  final bool selected;

  final bool interactive;

  final bool isDark;

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

  (Color, Color) _tonePair(FThemeData theme) {
    if (widget.selected) {
      final opacity = widget.isDark ? 0.20 : 0.10;
      return (
        theme.colors.primary.withValues(alpha: opacity),
        theme.colors.primary,
      );
    }
    final tone = widget.chip.tone;
    if (tone == null) {
      return (theme.colors.secondary, theme.colors.secondaryForeground);
    }
    final opacity = widget.isDark ? 0.20 : 0.10;
    return (tone.withValues(alpha: opacity), tone);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final interactive = widget.interactive;
    final (fill, content) = _tonePair(theme);
    final hovering = _hovering && interactive;
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
        selected: widget.selected,
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: interactive ? 32 : 20,
            padding: EdgeInsets.symmetric(horizontal: interactive ? 12 : 8),
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              color: hovering ? theme.colors.muted : fill,
              shape: StadiumBorder(
                side: widget.selected
                    ? BorderSide(color: theme.colors.primary.withValues(alpha: 0.6))
                    : _focused
                    ? BorderSide(color: theme.colors.primary.withValues(alpha: 0.5), width: 2)
                    : BorderSide.none,
              ),
            ),
            child: Text(
              widget.chip.label,
              style: theme.typography.body.xs.copyWith(
                color: content,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
