import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/adaptive/app_presentation_policy.dart';

class FormSubmitButton extends StatelessWidget {
  const FormSubmitButton({
    required this.onPress,
    required this.label,
    this.buttonKey,
    this.focusNode,
    this.busy = false,
    this.locked = false,
    this.retainFocusOnBusy = false,
    this.isTenFoot,
    this.variant = FButtonVariant.primary,
    this.mainAxisSize = MainAxisSize.max,
    this.autofocus = false,
    super.key,
  });

  final VoidCallback onPress;

  final Key? buttonKey;

  final String label;

  final FocusNode? focusNode;

  final bool busy;

  final bool locked;

  final bool retainFocusOnBusy;

  final bool? isTenFoot;

  final FButtonVariant variant;

  final MainAxisSize mainAxisSize;

  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final tenFoot = isTenFoot ?? context.isTenFoot;
    final VoidCallback? effective;
    if (busy && retainFocusOnBusy && tenFoot) {
      effective = () {};
    } else if (busy || locked) {
      effective = null;
    } else {
      effective = onPress;
    }
    return FButton(
      key: buttonKey,
      variant: variant,
      focusNode: focusNode,
      autofocus: autofocus,
      onPress: effective,
      mainAxisSize: mainAxisSize,
      builder: (_, _, _, _, _, child) => Flexible(child: child!),
      child: Text(
        label,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );
  }
}
