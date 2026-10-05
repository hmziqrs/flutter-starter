import 'dart:async';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/app_sizes.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/busy_overlay.dart';
import 'package:starter/shared/widgets/forms/form_submit_button.dart';

class FormScaffold extends StatelessWidget {
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

  final GlobalKey<FormState> formKey;

  final Widget fields;

  final FutureOr<void> Function() onSubmit;

  final String submitLabel;

  final bool isValid;

  final bool isSubmitting;

  final String? busyLabel;

  final Widget? heading;

  final Widget? subheading;

  final bool groupInCard;

  final Key submitKey;

  @override
  Widget build(BuildContext context) {
    return BusyOverlay(
      isBusy: isSubmitting,
      label: busyLabel,
      child: FScaffold(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsetsDirectional.all(context.spacing.xl2),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSizes.formContentMaxWidth,
                ),
                child: _body(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final spacing = context.spacing;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (heading != null) ...[
          heading!,
          SizedBox(height: spacing.md),
        ],
        if (subheading != null) ...[
          subheading!,
          SizedBox(height: spacing.xl),
        ],
        Form(key: formKey, child: fields),
        SizedBox(height: spacing.xl),
        FormSubmitButton(
          buttonKey: submitKey,
          label: submitLabel,
          onPress: onSubmit,
          busy: isSubmitting,
          locked: !isValid,
        ),
      ],
    );

    if (!groupInCard) {
      return content;
    }
    return FCard(
      child: Padding(
        padding: EdgeInsets.all(spacing.xl),
        child: content,
      ),
    );
  }
}
