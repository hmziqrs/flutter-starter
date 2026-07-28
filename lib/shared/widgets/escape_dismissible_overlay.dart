import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Gives modal content a consistent keyboard Escape dismissal action.
class EscapeDismissibleOverlay extends StatefulWidget {
  const EscapeDismissibleOverlay({required this.child, super.key});

  final Widget child;

  @override
  State<EscapeDismissibleOverlay> createState() => _EscapeDismissibleOverlayState();
}

class _EscapeDismissibleOverlayState extends State<EscapeDismissibleOverlay> {
  late final FocusNode _fallbackFocus = FocusNode(
    debugLabel: 'escape-dismissible-overlay.fallback',
    skipTraversal: true,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_ensureFocusInsideOverlay());
    });
  }

  @override
  void dispose() {
    _fallbackFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          unawaited(Navigator.of(context).maybePop());
        },
      },
      child: Focus(
        focusNode: _fallbackFocus,
        skipTraversal: true,
        child: widget.child,
      ),
    );
  }

  Future<void> _ensureFocusInsideOverlay() async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) {
      return;
    }
    final primaryFocus = FocusManager.instance.primaryFocus;
    final isInside =
        primaryFocus == _fallbackFocus ||
        (primaryFocus?.ancestors.contains(_fallbackFocus) ?? false);
    if (!isInside && _fallbackFocus.canRequestFocus) {
      _fallbackFocus.requestFocus();
    }
  }
}
