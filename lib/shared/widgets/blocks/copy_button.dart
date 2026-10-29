import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/brand_tokens.dart';

/// How an [AppCopyButton] sits on its surface: `ghost` is the icon-only
/// button inside a code block's header bar or the command box (the svelte
/// CopyButton with no label), `outline` is the labelled button whose word
/// sits beside the icon and flips with it (the svelte `{#if label}`
/// branch: `Copied` replaces the label once copied).
enum AppCopyButtonStyle { ghost, outline }

/// The brand copy button (BRAND.md s6): the Copy icon flips to a green
/// Check when copied, then back after two seconds.
///
/// The outline variant also shows the caller's word beside the icon, so
/// free-standing buttons say what they do; the ghost variant stays
/// icon-only and announces itself through [label]. Icon-only controls need
/// a semantics label, so [label] and [copiedLabel] come from the caller.
/// Feedback is color only — the icon and word swap, nothing moves.
class AppCopyButton extends StatefulWidget {
  const AppCopyButton({
    required this.text,
    required this.label,
    this.copiedLabel,
    this.style = AppCopyButtonStyle.ghost,
    super.key,
  });

  /// The text this button puts on the clipboard.
  final String text;

  /// The label at rest, e.g. "Copy" — visible on the outline variant and
  /// the semantics label on both.
  final String label;

  /// The label once copied, e.g. "Copied"; falls back to `"Copied"` — the
  /// svelte button always says "Copied" while the check shows, whatever the
  /// rest label says.
  final String? copiedLabel;

  final AppCopyButtonStyle style;

  @override
  State<AppCopyButton> createState() => _AppCopyButtonState();
}

class _AppCopyButtonState extends State<AppCopyButton> {
  static const _revertAfter = Duration(seconds: 2);

  bool _copied = false;
  Timer? _revertTimer;

  @override
  void dispose() {
    _revertTimer?.cancel();
    super.dispose();
  }

  void _copy() {
    unawaited(Clipboard.setData(ClipboardData(text: widget.text)));
    _revertTimer?.cancel();
    setState(() => _copied = true);
    _revertTimer = Timer(_revertAfter, () {
      if (mounted) {
        setState(() => _copied = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final copied = _copied;
    final resolvedLabel = copied ? (widget.copiedLabel ?? 'Copied') : widget.label;
    return FButton(
      variant: widget.style == AppCopyButtonStyle.ghost
          ? FButtonVariant.ghost
          : FButtonVariant.outline,
      size: FButtonSizeVariant.sm,
      onPress: _copy,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            copied ? FLucideIcons.check : FLucideIcons.copy,
            size: 16,
            color: copied ? theme.brand.success : null,
            semanticLabel: resolvedLabel,
          ),
          if (widget.style == AppCopyButtonStyle.outline) ...<Widget>[
            // The sm button's icon-to-label gap is gap-1 (4dp) in the kit's
            // button recipe.
            const SizedBox(width: 4),
            Text(resolvedLabel),
          ],
        ],
      ),
    );
  }
}
