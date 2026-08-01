import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/feedback/feedback_controller.dart';
import 'package:starter/features/feedback/feedback_presentation_state.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/forms/form_validators.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/busy_indicator.dart';
import 'package:starter/shared/widgets/escape_dismissible_overlay.dart';

Future<bool> showFeedbackSheet({required BuildContext context}) async {
  final accepted = await showFSheet<bool>(
    context: context,
    side: FLayout.btt,
    useSafeArea: true,
    builder: (sheetContext) => ColoredBox(
      color: sheetContext.theme.colors.background,
      child: EscapeDismissibleOverlay(
        child: FeedbackSheetBody(
          onDismiss: () => Navigator.of(sheetContext).maybePop(false),
          onAccepted: () => Navigator.of(sheetContext).maybePop(true),
        ),
      ),
    ),
  );
  return accepted ?? false;
}

class FeedbackSheetBody extends ConsumerStatefulWidget {
  const FeedbackSheetBody({
    required this.onDismiss,
    required this.onAccepted,
    this.presentation,
    this.includeScreenshot = false,
    super.key,
  });

  final VoidCallback onDismiss;

  final VoidCallback onAccepted;

  final FeedbackPresentationState? presentation;

  final bool includeScreenshot;

  @override
  ConsumerState<FeedbackSheetBody> createState() => _FeedbackSheetBodyState();
}

class _FeedbackSheetBodyState extends ConsumerState<FeedbackSheetBody> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageFocus = FocusNode(debugLabel: 'feedback.message');
  final _emailFocus = FocusNode(debugLabel: 'feedback.email');
  bool _seedsApplied = false;
  bool _includeScreenshot = false;

  @override
  void initState() {
    super.initState();
    _applySeedIfNeeded();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _applySeedIfNeeded();
  }

  void _applySeedIfNeeded() {
    if (_seedsApplied) return;
    if (widget.presentation != null) {
      _includeScreenshot = widget.includeScreenshot;
      _seedsApplied = true;
      return;
    }
    final draft = ref.read(feedbackControllerProvider).draft;
    _messageController.text = draft.message;
    _messageController.selection = TextSelection.collapsed(offset: draft.message.length);
    _emailController.text = draft.email ?? '';
    _includeScreenshot = draft.includeScreenshot;
    _seedsApplied = true;
  }

  @override
  void dispose() {
    _messageController.dispose();
    _emailController.dispose();
    _messageFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final translations = context.t.feedback;
    final live = ref.watch(feedbackControllerProvider);
    final presentation = widget.presentation ?? live.presentation;
    final isFixture = widget.presentation != null;
    final busy = presentation.isBusy;
    final includeScreenshot = isFixture ? _includeScreenshot : live.draft.includeScreenshot;

    return Semantics(
      label: translations.title,
      container: true,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(title: translations.title),
              const SizedBox(height: AppSpacing.md),
              switch (presentation.status) {
                FeedbackPresentationStatus.success => _SuccessCopy(
                  title: translations.successTitle,
                  body: translations.successBody,
                ),
                _ => _buildForm(
                  context: context,
                  presentation: presentation,
                  includeScreenshot: includeScreenshot,
                  busy: busy,
                  isFixture: isFixture,
                ),
              },
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm({
    required BuildContext context,
    required FeedbackPresentationState presentation,
    required bool includeScreenshot,
    required bool busy,
    required bool isFixture,
  }) {
    final translations = context.t;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FTextFormField(
            key: const ValueKey('feedback-message'),
            control: .managed(
              controller: _messageController,
              onChange: isFixture ? null : (value) => _pushMessage(value.text),
            ),
            focusNode: _messageFocus,
            label: Text(translations.feedback.messageLabel),
            hint: translations.feedback.messageHint,
            minLines: 4,
            maxLines: 8,
            textInputAction: TextInputAction.newline,
            enabled: !busy,
            textCapitalization: TextCapitalization.sentences,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return translations.validation.required(
                  field: translations.feedback.messageLabel,
                );
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          FTextFormField(
            key: const ValueKey('feedback-email'),
            control: .managed(
              controller: _emailController,
              onChange: isFixture ? null : (value) => _pushEmail(value.text),
            ),
            focusNode: _emailFocus,
            label: Text('${translations.feedback.emailOptional} (${translations.common.optional})'),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            enabled: !busy,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return null;
              return validateEmail(
                value,
                requiredMessage: translations.validation.email,
                invalidMessage: translations.validation.email,
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          FSwitch(
            key: const ValueKey('feedback-include-screenshot'),
            value: includeScreenshot,
            label: Text(translations.feedback.includeScreenshot),
            enabled: !busy,
            onChange: isFixture ? null : _pushIncludeScreenshot,
          ),
          if (_feedbackAlert(context, presentation) case final alert?) ...[
            const SizedBox(height: AppSpacing.md),
            alert,
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              if (busy) const BusyIndicator(),
              Expanded(
                child: FButton(
                  key: const ValueKey('feedback-submit'),
                  onPress: busy ? null : () => unawaited(_submit(presentation, isFixture)),
                  child: Text(translations.feedback.submit),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          FButton(
            key: const ValueKey('feedback-cancel'),
            variant: .ghost,
            onPress: busy ? null : widget.onDismiss,
            child: Text(translations.feedback.cancel),
          ),
        ],
      ),
    );
  }

  Widget? _feedbackAlert(BuildContext context, FeedbackPresentationState presentation) {
    final translations = context.t;
    return switch (presentation.status) {
      FeedbackPresentationStatus.idle ||
      FeedbackPresentationStatus.drafting ||
      FeedbackPresentationStatus.validating ||
      FeedbackPresentationStatus.submitting => null,
      FeedbackPresentationStatus.success => null,
      FeedbackPresentationStatus.failed => FAlert(
        key: const ValueKey('feedback-failed'),
        variant: .destructive,
        title: Text(translations.common.notConnected),
        subtitle: Text(translations.feedback.failedTitle),
      ),
    };
  }

  void _pushMessage(String value) {
    ref.read(feedbackControllerProvider.notifier).setMessage(value);
  }

  void _pushEmail(String value) {
    ref.read(feedbackControllerProvider.notifier).setEmail(value);
  }

  void _pushIncludeScreenshot(bool value) {
    ref.read(feedbackControllerProvider.notifier).setIncludeScreenshot(value: value);
  }

  Future<void> _submit(FeedbackPresentationState presentation, bool isFixture) async {
    if (presentation.isBusy) return;
    if (isFixture) {
      widget.onAccepted();
      return;
    }
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) {
      _messageFocus.requestFocus();
      return;
    }
    form.save();
    final accepted = await ref.read(feedbackControllerProvider.notifier).submit();
    if (!mounted) return;
    if (accepted) {
      widget.onAccepted();
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(FLucideIcons.messageSquare, size: 24),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(title, style: context.theme.typography.display.lg),
        ),
      ],
    );
  }
}

class _SuccessCopy extends StatelessWidget {
  const _SuccessCopy({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FAlert(
          icon: const Icon(FLucideIcons.circleCheck),
          title: Text(title),
          subtitle: Text(body),
        ),
      ],
    );
  }
}
