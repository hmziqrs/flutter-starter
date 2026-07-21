import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Gives modal content a consistent keyboard Escape dismissal action.
class EscapeDismissibleOverlay extends StatelessWidget {
  const EscapeDismissibleOverlay({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          unawaited(Navigator.of(context).maybePop());
        },
      },
      child: Focus(autofocus: true, child: child),
    );
  }
}
