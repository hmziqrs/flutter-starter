import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/adaptive/app_presentation_policy.dart';

/// A canonical submit / call-to-action button for forms.
///
/// Wraps [FButton] with the standard primary-action chrome used across the app:
/// a [Flexible] content wrapper and a label rendered with `maxLines: 2`,
/// ellipsis, and center alignment.
///
/// The press-absorber canonicalizes the busy / ten-foot focus-retention rule:
///   * while [busy] with [retainFocusOnBusy] enabled on a ten-foot surface, the
///     button stays focusable but swallows presses (onPress stays non-null),
///     so remote / keyboard focus is not lost mid-submit;
///   * otherwise, while [busy] or [locked], the button is disabled.
///
/// Set [retainFocusOnBusy] on auth submit buttons that must hold focus while
/// their async callback runs. Leave it false (the default) on generic scaffolds
/// (such as `FormScaffold`) that simply disable while submitting.
///
/// [variant] selects the [FButton] variant; pass [FButtonVariant.ghost] for the
/// secondary / navigation style. The effective ten-foot state is read from
/// `BuildContext.isTenFoot` unless [isTenFoot] is supplied (e.g. for tests).
///
/// The caller's [buttonKey] is forwarded onto the underlying [FButton] (not kept
/// on this wrapper) so that `find.byKey(buttonKey)` resolves to the [FButton]
/// itself — matching the introspection contract used by widget tests that cast
/// the hit to `FButton`. The inherited [key] (via `super.key`) is kept on this
/// wrapper widget itself, as required for public widgets; callers that want the
/// introspectable surface must pass [buttonKey] instead.
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

  /// Invoked when the button is pressed and not busy / locked.
  final VoidCallback onPress;

  /// Key forwarded onto the underlying [FButton] (see class docs).
  final Key? buttonKey;

  /// Label rendered with the canonical text wrapping.
  final String label;

  /// Optional focus node for the underlying [FButton].
  final FocusNode? focusNode;

  /// While true the button is disabled, or — when [retainFocusOnBusy] and
  /// ten-foot — absorbs presses without invoking [onPress].
  final bool busy;

  /// Forces the button disabled regardless of [busy] (e.g. lockout /
  /// cooldown). Has no effect while [busy] retains focus.
  final bool locked;

  /// When true, a ten-foot busy button absorbs presses to retain focus instead
  /// of disabling. Defaults to false (disable-while-busy).
  final bool retainFocusOnBusy;

  /// Overrides the ten-foot detection from `BuildContext.isTenFoot`. Mainly for
  /// tests; leave null in production.
  final bool? isTenFoot;

  /// The [FButton] variant. Defaults to [FButtonVariant.primary].
  final FButtonVariant variant;

  /// The [mainAxisSize]; use [MainAxisSize.min] inside a [Wrap].
  final MainAxisSize mainAxisSize;

  /// See [FButton.autofocus].
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final tenFoot = isTenFoot ?? context.isTenFoot;
    final VoidCallback? effective;
    if (busy && retainFocusOnBusy && tenFoot) {
      // Stay focusable on ten-foot surfaces so remote focus is retained, but
      // swallow the press while the async callback is in flight.
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
