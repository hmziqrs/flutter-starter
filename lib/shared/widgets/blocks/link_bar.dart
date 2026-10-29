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

/// A link to copy (link-bar.svelte): the address in mono inside the
/// command bar's outline — the URL without `https://`, then a labelled
/// copy button.
///
/// [actions] extend the bar the way share-bar.svelte's `bar` variant does:
/// small round outlined buttons after the bar, whose icons take the text
/// color and whose border warms on hover. Feedback is color only.
class AppLinkBar extends StatelessWidget {
  const AppLinkBar({
    required this.url,
    required this.copyLabel,
    this.actions = const [],
    super.key,
  });

  /// The address to show and copy; `https://` is stripped for display.
  final String url;

  /// The copy button's semantics label, e.g. "Copy link".
  final String copyLabel;

  final List<AppLinkAction> actions;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final displayUrl = url.startsWith('https://') ? url.substring('https://'.length) : url;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        Container(
          // The bar: w-fit, gap-4, rounded-xl, border, py-1.5 pr-1.5
          // pl-4.5 (link-bar.svelte).
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsetsDirectional.fromSTEB(18, 6, 6, 6),
          decoration: ShapeDecoration(
            shape: RoundedSuperellipseBorder(
              side: BorderSide(color: theme.colors.border, width: theme.style.borderWidth),
              borderRadius: theme.style.borderRadius.lg,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Flexible(
                child: Text(
                  displayUrl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  // The address runs in mono at the body size, in the
                  // normal text color — machine value, not muted words.
                  style: theme.typography.body.sm.copyWith(
                    fontFamily: 'JetBrains Mono',
                  ),
                ),
              ),
              // gap-4 between address and button.
              const SizedBox(width: 16),
              AppCopyButton(text: url, label: copyLabel, style: AppCopyButtonStyle.outline),
            ],
          ),
        ),
        for (final action in actions) _RoundAction(action: action),
      ],
    );
  }
}

/// The share networks' round button (share-bar.svelte's rings): 36dp with a
/// 1px outline; the icon takes the text color and hover warms the border.
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
            // size-9 (36) with the ring outline.
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              shape: CircleBorder(
                side: BorderSide(
                  // Hover warms the border to foreground/45
                  // (`hover:border-foreground/45`); focus draws the
                  // primary ring at half strength (ring-3 at 50%).
                  color: _focused
                      ? theme.colors.primary.withValues(alpha: 0.5)
                      : _hovering
                      ? theme.colors.foreground.withValues(alpha: 0.45)
                      : theme.colors.border,
                  width: _focused ? 3 : theme.style.borderWidth,
                ),
              ),
            ),
            child: Icon(
              widget.action.icon,
              // size-3.75 (15).
              size: 15,
              // The icons take the text color; they are not statuses.
              color: theme.colors.foreground,
            ),
          ),
        ),
      ),
    );
  }
}
