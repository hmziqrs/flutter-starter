import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/widgets/blocks/copy_button.dart';

/// One round share action of an [AppLinkBar].
class AppLinkAction {
  const AppLinkAction({required this.icon, required this.label, required this.onPressed});

  /// The Lucide icon (from FLucideIcons) for the network or action.
  final IconData icon;

  /// The icon-only control's semantics label, e.g. "Share on Bluesky".
  final String label;

  final VoidCallback onPressed;
}

/// The share bar (BRAND.md s8, blog post pattern): the address in mono, a
/// copy button, then the caller's networks as small round buttons whose
/// icons take the text color.
class AppLinkBar extends StatelessWidget {
  const AppLinkBar({
    required this.url,
    required this.copyLabel,
    this.actions = const [],
    super.key,
  });

  /// The address to show and copy.
  final String url;

  /// The copy button's semantics label, e.g. "Copy link".
  final String copyLabel;

  final List<AppLinkAction> actions;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Text(
            url,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 13,
              color: theme.colors.mutedForeground,
            ),
          ),
        ),
        AppCopyButton(text: url, label: copyLabel),
        for (final action in actions) _RoundAction(action: action),
      ],
    );
  }
}

class _RoundAction extends StatefulWidget {
  const _RoundAction({required this.action});

  final AppLinkAction action;

  @override
  State<_RoundAction> createState() => _RoundActionState();
}

class _RoundActionState extends State<_RoundAction> {
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
            widget.action.onPressed();
            return null;
          },
        ),
      },
      child: Semantics(
        button: true,
        label: widget.action.label,
        child: GestureDetector(
          onTap: widget.action.onPressed,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              color: _hovering ? theme.colors.muted : Colors.transparent,
              shape: CircleBorder(
                side: _focused
                    ? BorderSide(color: theme.colors.primary.withValues(alpha: 0.5), width: 2)
                    : BorderSide.none,
              ),
            ),
            child: Icon(
              widget.action.icon,
              size: 16,
              // The icons take the text color; they are not statuses.
              color: theme.colors.foreground,
            ),
          ),
        ),
      ),
    );
  }
}
