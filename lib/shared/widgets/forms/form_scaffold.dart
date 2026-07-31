import 'dart:async';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/app_sizes.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/busy_overlay.dart';

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
