import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/shared/adaptive/app_presentation_policy.dart';
import 'package:starter/shared/forms/form_field_reveal.dart';

mixin AuthFormSubmitMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  bool _callbackSubmitting = false;

  bool get callbackSubmitting => _callbackSubmitting;

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
