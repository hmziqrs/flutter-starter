import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/brand_tokens.dart';

/// How an [AppCopyButton] sits on its surface: `ghost` inside a code
/// block's header bar, `outline` free-standing as in the command bar.
enum AppCopyButtonStyle { ghost, outline }

/// The brand copy button (BRAND.md s6): a ghost icon button whose Copy icon
/// flips to a green Check when copied, then back after two seconds.
///
/// Icon-only controls need a semantics label, so [label] and [copiedLabel]
/// come from the caller. Feedback is color only — the icon swaps, nothing
/// moves.
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

  /// The semantics label at rest, e.g. "Copy".
  final String label;

  /// The semantics label once copied, e.g. "Copied".
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
    return FButton(
      variant: widget.style == AppCopyButtonStyle.ghost
          ? FButtonVariant.ghost
          : FButtonVariant.outline,
      size: FButtonSizeVariant.sm,
      onPress: _copy,
      child: Icon(
        copied ? FLucideIcons.check : FLucideIcons.copy,
        size: 16,
        color: copied ? theme.brand.success : null,
        semanticLabel: copied ? (widget.copiedLabel ?? widget.label) : widget.label,
      ),
    );
  }
}
