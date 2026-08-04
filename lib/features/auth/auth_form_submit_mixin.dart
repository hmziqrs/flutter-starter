import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/shared/adaptive/app_presentation_policy.dart';
import 'package:starter/shared/forms/form_field_reveal.dart';

/// Submit-flow orchestration shared by the auth form pages.
///
/// Reproduces the exact submit ordering used by every auth page: granular
/// validation, reveal-and-focus the first invalid field, save the form, build
/// the typed value, request the submit focus on ten-foot surfaces, flip the
/// local submitting flag, finish the autofill context, await the page's submit
/// callback, then clear the flag.
///
/// Pages mix this in and combine [callbackSubmitting] with their presentation
/// status to derive their composite `submitting` getter, e.g.
/// `get submitting => callbackSubmitting || status == Status.submitting;`.
mixin AuthFormSubmitMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  /// Whether this view is currently driving a local submit callback.
  ///
  /// The submit method toggles this around the awaited callback. Pages fold it
  /// into their composite `_submitting` getter alongside the presentation
  /// status; the leading `if (_callbackSubmitting) return;` guard below covers
  /// the local re-entrancy half of the original `if (_submitting) return;`.
  bool _callbackSubmitting = false;

  bool get callbackSubmitting => _callbackSubmitting;

  /// Runs the shared submit flow.
  ///
  /// [orderedTargets] drives the first-invalid reveal via [revealFirstInvalid]
  /// and must be ordered to match the page's field traversal (the OTP page
  /// passes a single target; register passes all five). [buildValue] is the
  /// only true variation point between pages; it runs after `form.save()`.
  /// [tenFootFocusNode], when provided, receives focus on ten-foot surfaces
  /// just before the submitting flag flips, mirroring each page's
  /// `_submitFocus.requestFocus()` step.
  Future<void> submit<U>({
    required GlobalKey<FormState> formKey,
    required Iterable<InvalidFieldTarget> orderedTargets,
    required U Function() buildValue,
    required Future<void> Function(U value) onSubmit,
    FocusNode? tenFootFocusNode,
  }) async {
    if (_callbackSubmitting) return;
    final form = formKey.currentState;
    if (form == null) return;

    final invalidFields = form.validateGranularly();
    if (invalidFields.isNotEmpty) {
      await revealFirstInvalid(
        invalidFields,
        orderedTargets: orderedTargets,
        isMounted: () => mounted,
      );
      return;
    }

    form.save();
    final value = buildValue();

    if (AppPresentationPolicy.maybeOf(context)?.isTenFoot ?? false) {
      tenFootFocusNode?.requestFocus();
    }
    setState(() => _callbackSubmitting = true);
    TextInput.finishAutofillContext(shouldSave: false);
    try {
      await onSubmit(value);
    } finally {
      if (mounted) setState(() => _callbackSubmitting = false);
    }
  }
}
