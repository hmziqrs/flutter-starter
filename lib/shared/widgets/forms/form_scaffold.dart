import 'dart:async';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/app_sizes.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/busy_overlay.dart';

/// A reusable form shell: a ForUI [FScaffold] with optional [FCard] grouping,
/// a submit [FButton] that stays disabled until [isValid], and a modal
/// [BusyOverlay] mounted while [isSubmitting].
///
/// The caller owns the [Form] state (via [formKey]), the typed field values,
/// validation, and the first-invalid reveal; this widget only standardizes the
/// chrome and the submit/busy affordance. The submit callback ([onSubmit]) is
/// feature-supplied and performs the `validate()` → reveal → `save()` → async
/// submit sequence from the feature's own presentation state.
class FormScaffold extends StatelessWidget {
  /// Creates a [FormScaffold].
  const FormScaffold({
    required this.formKey,
    required this.fields,
    required this.onSubmit,
    required this.submitLabel,
    required this.isValid,
    this.isSubmitting = false,
    this.busyLabel,
    this.heading,
    this.subheading,
    this.groupInCard = true,
    this.submitKey = const ValueKey('form-scaffold-submit'),
    super.key,
  });

  /// The key of the [Form] that parents [fields]; reach it from [onSubmit] via
  /// `formKey.currentState` to `validate()` / `save()`.
  final GlobalKey<FormState> formKey;

  /// The form-field widgets placed inside the mounted [Form].
  final Widget fields;

  /// Invoked when the submit button is pressed while enabled. The caller
  /// performs validation, first-invalid reveal, save, and the async submit.
  final FutureOr<void> Function() onSubmit;

  /// Caption shown on the submit [FButton].
  final String submitLabel;

  /// Gates the submit button's enabled state. `false` keeps the button
  /// disabled so an incomplete form cannot be submitted.
  final bool isValid;

  /// Mounts the modal [BusyOverlay] over the form when `true`, blocking
  /// duplicate submits while the in-flight callback runs.
  final bool isSubmitting;

  /// Optional caption forwarded to [BusyOverlay.label]. Defaults to the
  /// localized `common.saving` when omitted.
  final String? busyLabel;

  /// Optional heading rendered above [fields].
  final Widget? heading;

  /// Optional subheading rendered beneath [heading].
  final Widget? subheading;

  /// Whether to wrap the form body in an [FCard]. Defaults to `true`.
  final bool groupInCard;

  /// Stable identity for the submit [FButton] (widget/integration tests).
  final Key submitKey;

  @override
  Widget build(BuildContext context) {
    final enabled = isValid && !isSubmitting;
    return BusyOverlay(
      isBusy: isSubmitting,
      label: busyLabel,
      child: FScaffold(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsetsDirectional.all(AppSpacing.xl2),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSizes.formContentMaxWidth,
                ),
                child: _body(enabled),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(bool enabled) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (heading != null) ...[
          heading!,
          const SizedBox(height: AppSpacing.md),
        ],
        if (subheading != null) ...[
          subheading!,
          const SizedBox(height: AppSpacing.xl),
        ],
        Form(key: formKey, child: fields),
        const SizedBox(height: AppSpacing.xl),
        FButton(
          key: submitKey,
          onPress: enabled ? onSubmit : null,
          builder: (_, _, _, _, _, child) => Flexible(child: child!),
          child: Text(
            submitLabel,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );

    if (!groupInCard) {
      return content;
    }
    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: content,
      ),
    );
  }
}
