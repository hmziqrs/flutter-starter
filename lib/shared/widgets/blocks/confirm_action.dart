import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/brand_tokens.dart';
import 'package:starter/shared/widgets/escape_dismissible_overlay.dart';

/// Runs a step that deserves a second look (APP-BLOCKS.md "ConfirmAction"):
/// removing people, deleting a workspace.
///
/// The dialog states the consequences in words, the confirm button says
/// what happens — never "OK" — and an irreversible action can demand a word
/// typed first. [onConfirm] does the work and returns `null` when it
/// succeeded or the error message to show; the dialog stays open on an
/// error so it can be tried again. All copy comes from the caller.
///
/// The confirm button is destructive-soft: red text on a 10% red fill (20%
/// in dark). Status is always soft; only orange may fill solid behind text.
class AppConfirmAction extends StatefulWidget {
  const AppConfirmAction({
    required this.title,
    required this.description,
    required this.confirmLabel,
    required this.onConfirm,
    this.confirmPendingLabel,
    this.cancelLabel,
    this.confirmText,
    this.confirmPrompt,
    this.trigger,
    this.triggerLabel,
    super.key,
  });

  /// The dialog's title, e.g. "Remove Ada Lovelace?".
  final String title;

  /// What happens, and whether it can be undone.
  final String description;

  /// The confirm button's label; it says what happens, e.g. "Remove member".
  final String confirmLabel;

  /// The confirm button's label while [onConfirm] runs.
  final String? confirmPendingLabel;

  /// The cancel button's label.
  final String? cancelLabel;

  /// The word that unlocks the confirm button, for irreversible actions.
  final String? confirmText;

  /// The line that names the word to type, e.g. "Type Paperplane to
  /// confirm". Shown when [confirmText] is set.
  final String? confirmPrompt;

  /// A caller-built trigger to open the dialog. Wrap a plain widget; if it
  /// handles its own taps the dialog never opens. Leave null to use the
  /// default destructive-soft button labeled by [triggerLabel].
  final Widget? trigger;

  /// The default trigger's label. Required when [trigger] is null.
  final String? triggerLabel;

  /// The action to confirm. Returns `null` on success or the error message
  /// to show inside the dialog.
  final Future<String?> Function() onConfirm;

  @override
  State<AppConfirmAction> createState() => _AppConfirmActionState();
}

class _AppConfirmActionState extends State<AppConfirmAction> {
  bool _hovering = false;
  bool _focused = false;
  late final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    await showFDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext, style, animation) => EscapeDismissibleOverlay(
        child: FDialog(
          animation: animation,
          semanticsLabel: widget.title,
          builder: (context, _) => _ConfirmDialogBody(action: widget),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trigger = widget.trigger;
    if (trigger != null) {
      return GestureDetector(onTap: _open, child: trigger);
    }
    final theme = context.theme;
    final destructive = theme.brand.destructive;
    final fillOpacity = theme.colors.brightness == Brightness.dark ? 0.20 : 0.10;
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
            unawaited(_open());
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTap: _open,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: destructive.withValues(alpha: _hovering ? fillOpacity + 0.1 : fillOpacity),
            shape: RoundedSuperellipseBorder(
              side: _focused
                  ? BorderSide(color: theme.colors.primary.withValues(alpha: 0.5), width: 2)
                  : BorderSide.none,
              borderRadius: theme.style.borderRadius.sm,
            ),
          ),
          child: Text(
            widget.triggerLabel ?? '',
            style: theme.typography.body.sm.copyWith(
              color: destructive,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfirmDialogBody extends StatefulWidget {
  const _ConfirmDialogBody({required this.action});

  final AppConfirmAction action;

  @override
  State<_ConfirmDialogBody> createState() => _ConfirmDialogBodyState();
}

class _ConfirmDialogBodyState extends State<_ConfirmDialogBody> {
  final TextEditingController _controller = TextEditingController();
  bool _pending = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _confirmEnabled {
    final confirmText = widget.action.confirmText;
    if (_pending) {
      return false;
    }
    if (confirmText == null) {
      return true;
    }
    return _controller.text == confirmText;
  }

  Future<void> _confirm() async {
    if (!_confirmEnabled) {
      return;
    }
    setState(() {
      _pending = true;
      _error = null;
    });
    final message = await widget.action.onConfirm();
    if (!mounted) {
      return;
    }
    if (message == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _pending = false;
      _error = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final destructive = theme.brand.destructive;
    final confirmText = widget.action.confirmText;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            widget.action.title,
            style: theme.typography.body.sm.copyWith(
              color: theme.colors.foreground,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.action.description,
            style: theme.typography.body.sm.copyWith(color: theme.colors.mutedForeground),
          ),
          if (confirmText != null) ...<Widget>[
            const SizedBox(height: 16),
            if (widget.action.confirmPrompt != null) ...<Widget>[
              Text(
                widget.action.confirmPrompt!,
                style: theme.typography.body.sm.copyWith(
                  color: theme.colors.foreground,
                ),
              ),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: _controller,
              autofocus: true,
              enabled: !_pending,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => unawaited(_confirm()),
              style: theme.typography.body.sm.copyWith(color: theme.colors.foreground),
              cursorColor: theme.colors.primary,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                filled: false,
                enabledBorder: OutlineInputBorder(
                  borderRadius: theme.style.borderRadius.sm,
                  borderSide: BorderSide(color: theme.colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: theme.style.borderRadius.sm,
                  borderSide: BorderSide(
                    color: theme.colors.primary.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: theme.style.borderRadius.sm,
                  borderSide: BorderSide(color: theme.colors.border),
                ),
              ),
            ),
          ],
          if (_error != null) ...<Widget>[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: theme.typography.body.sm.copyWith(color: destructive),
            ),
          ],
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              FButton(
                variant: FButtonVariant.outline,
                mainAxisSize: MainAxisSize.min,
                autofocus: confirmText == null,
                onPress: _pending ? null : () => Navigator.of(context).pop(),
                child: Text(
                  widget.action.cancelLabel ?? '',
                  style: theme.typography.body.sm.copyWith(
                    color: theme.colors.foreground,
                  ),
                ),
              ),
              _SoftDestructiveButton(
                label: _pending
                    ? (widget.action.confirmPendingLabel ?? widget.action.confirmLabel)
                    : widget.action.confirmLabel,
                enabled: _confirmEnabled,
                autofocus: false,
                onPress: _pending ? null : () => unawaited(_confirm()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The destructive-soft confirm button: red text on the role's soft fill,
/// never a solid red slab.
class _SoftDestructiveButton extends StatefulWidget {
  const _SoftDestructiveButton({
    required this.label,
    required this.enabled,
    required this.autofocus,
    this.onPress,
  });

  final String label;

  final bool enabled;

  final bool autofocus;

  final VoidCallback? onPress;

  @override
  State<_SoftDestructiveButton> createState() => _SoftDestructiveButtonState();
}

class _SoftDestructiveButtonState extends State<_SoftDestructiveButton> {
  bool _hovering = false;
  bool _focused = false;
  late final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.autofocus && widget.enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final destructive = theme.brand.destructive;
    final fillOpacity = theme.colors.brightness == Brightness.dark ? 0.20 : 0.10;
    final enabled = widget.enabled;
    _focusNode.canRequestFocus = enabled;
    return FocusableActionDetector(
      focusNode: _focusNode,
      mouseCursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onShowHoverHighlight: enabled ? (hovering) => setState(() => _hovering = hovering) : null,
      onShowFocusHighlight: (focused) => setState(() => _focused = focused),
      shortcuts: enabled
          ? const <ShortcutActivator, Intent>{
              SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
              SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
            }
          : null,
      actions: enabled
          ? <Type, Action<Intent>>{
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (_) {
                  widget.onPress?.call();
                  return null;
                },
              ),
            }
          : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: destructive.withValues(alpha: _hovering ? fillOpacity + 0.1 : fillOpacity),
            shape: RoundedSuperellipseBorder(
              side: _focused
                  ? BorderSide(color: theme.colors.primary.withValues(alpha: 0.5), width: 2)
                  : BorderSide.none,
              borderRadius: theme.style.borderRadius.sm,
            ),
          ),
          child: Text(
            widget.label,
            style: theme.typography.body.sm.copyWith(
              color: destructive,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
