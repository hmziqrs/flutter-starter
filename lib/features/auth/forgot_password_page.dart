import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/auth/auth_form_submit_mixin.dart';
import 'package:starter/features/auth/auth_page_scaffold.dart';
import 'package:starter/features/auth/forgot_password_form_value.dart';
import 'package:starter/features/auth/forgot_password_presentation_state.dart';
import 'package:starter/features/auth/widgets/auth_feedback_alert.dart';
import 'package:starter/features/auth/widgets/auth_form_header.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/adaptive/app_layout_provider.dart';
import 'package:starter/shared/forms/email_form_field.dart';
import 'package:starter/shared/forms/restorable_text_controller.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/busy_overlay.dart';
import 'package:starter/shared/widgets/forms/form_submit_button.dart';

typedef ForgotPasswordSubmitCallback =
    FutureOr<void> Function(
      ForgotPasswordFormValue value,
    );

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({
    required this.onSubmit,
    required this.onLogin,
    this.presentation = const ForgotPasswordPresentationState(),
    super.key,
  });

  final ForgotPasswordSubmitCallback onSubmit;
  final VoidCallback onLogin;
  final ForgotPasswordPresentationState presentation;

  @override
  Widget build(BuildContext context) {
    return AppLayoutScope(
      builder: (context, _) => _ForgotPasswordView(
        onSubmit: onSubmit,
        onLogin: onLogin,
        presentation: presentation,
      ),
    );
  }
}

class _ForgotPasswordView extends ConsumerStatefulWidget {
  const _ForgotPasswordView({
    required this.onSubmit,
    required this.onLogin,
    required this.presentation,
  });

  final ForgotPasswordSubmitCallback onSubmit;
  final VoidCallback onLogin;
  final ForgotPasswordPresentationState presentation;

  @override
  ConsumerState<_ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends ConsumerState<_ForgotPasswordView>
    with
        RestorationMixin,
        RestorableTextControllerBinding<_ForgotPasswordView>,
        AuthFormSubmitMixin<_ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _emailFieldKey = GlobalKey<FormFieldState<String>>();
  final _emailController = TextEditingController();
  final _emailFocus = FocusNode(debugLabel: 'forgotPassword.email');
  final _submitFocus = FocusNode(debugLabel: 'forgotPassword.submit');

  final RestorableString _emailDraft = RestorableString('');
  late final VoidCallback _syncEmailDraft;

  bool get _submitting =>
      callbackSubmitting ||
      widget.presentation.status == ForgotPasswordPresentationStatus.submitting;

  @override
  String get restorationId => 'forgot-password-view';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerTextDraft(_emailDraft, 'email_draft');
    if (_emailController.text != _emailDraft.value) {
      _emailController.text = _emailDraft.value;
    }
  }

  @override
  void initState() {
    super.initState();
    _syncEmailDraft = textDraftSyncer(_emailDraft, _emailController);
    _emailController.addListener(_syncEmailDraft);
    _requestFixtureFocus();
  }

  @override
  void didUpdateWidget(covariant _ForgotPasswordView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.presentation.status != widget.presentation.status) {
      _requestFixtureFocus();
    }
  }

  void _requestFixtureFocus() {
    if (widget.presentation.status == ForgotPasswordPresentationStatus.focused) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _emailFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _emailController
      ..removeListener(_syncEmailDraft)
      ..dispose();
    _emailDraft.dispose();
    _emailFocus.dispose();
    _submitFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layoutClass = ref.watch(appLayoutClassProvider);
    final form = _buildForm(context);
    final translations = context.t.auth.forgotPassword;
    return BusyOverlay(
      isBusy: _submitting,
      label: translations.submitting,
      child: AuthPageScaffold(
        screenId: 'forgot-password',
        layoutClass: layoutClass,
        icon: FLucideIcons.keyRound,
        title: translations.title,
        body: translations.body,
        form: form,
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final translations = context.t;
    final status = widget.presentation.status;
    final forceEmailError =
        status == ForgotPasswordPresentationStatus.invalid ||
        status == ForgotPasswordPresentationStatus.fieldFailure;
    final feedbackAlert = AuthFeedbackAlert.forStatus(
      status: status,
      specFor: (status) => _feedbackSpec(context, status),
    );

    return AutofillGroup(
      onDisposeAction: AutofillContextAction.cancel,
      child: Form(
        key: _formKey,
        child: Column(
          key: const ValueKey('auth-forgot-password-form'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthFormHeader(
              title: translations.auth.forgotPassword.title,
              body: translations.auth.forgotPassword.body,
              alerts: feedbackAlert == null ? const [] : [feedbackAlert],
            ),
            emailFormField(
              activationKey: const ValueKey('auth-forgot-password-email-activation'),
              fieldKey: const ValueKey('auth-forgot-password-email'),
              label: translations.auth.common.email,
              controller: _emailController,
              focusNode: _emailFocus,
              formFieldKey: _emailFieldKey,
              enabled: !_submitting,
              autofocus: true,
              forceErrorText: forceEmailError ? translations.validation.email : null,
              textInputAction: TextInputAction.done,
              onSubmit: () => unawaited(_submit()),
            ),
            const SizedBox(height: AppSpacing.xl),
            FormSubmitButton(
              buttonKey: const ValueKey('auth-forgot-password-submit'),
              focusNode: _submitFocus,
              busy: _submitting,
              retainFocusOnBusy: true,
              onPress: () => unawaited(_submit()),
              label: translations.auth.forgotPassword.submit,
            ),
            const SizedBox(height: AppSpacing.md),
            FormSubmitButton(
              buttonKey: const ValueKey('auth-forgot-password-login'),
              variant: FButtonVariant.ghost,
              busy: _submitting,
              onPress: widget.onLogin,
              label: translations.auth.common.returnToLogin,
            ),
          ],
        ),
      ),
    );
  }

  AuthFeedbackAlertSpec? _feedbackSpec(
    BuildContext context,
    ForgotPasswordPresentationStatus status,
  ) {
    final translations = context.t;
    return switch (status) {
      ForgotPasswordPresentationStatus.idle ||
      ForgotPasswordPresentationStatus.focused ||
      ForgotPasswordPresentationStatus.submitting => null,
      ForgotPasswordPresentationStatus.invalid => AuthFeedbackAlertSpec(
        key: const ValueKey('auth-forgot-password-invalid'),
        variant: FAlertVariant.destructive,
        title: Text(translations.validation.email),
      ),
      ForgotPasswordPresentationStatus.fieldFailure => AuthFeedbackAlertSpec(
        key: const ValueKey('auth-forgot-password-field-failure'),
        variant: FAlertVariant.destructive,
        title: Text(translations.validation.email),
      ),
      ForgotPasswordPresentationStatus.globalFailure => AuthFeedbackAlertSpec(
        key: const ValueKey('auth-forgot-password-global-failure'),
        variant: FAlertVariant.destructive,
        title: Text(translations.common.notConnected),
      ),
      ForgotPasswordPresentationStatus.success => AuthFeedbackAlertSpec(
        key: const ValueKey('auth-forgot-password-success'),
        title: Text(translations.auth.forgotPassword.success),
        icon: const Icon(FLucideIcons.circleCheck),
      ),
    };
  }

  Future<void> _submit() => submit(
    formKey: _formKey,
    orderedTargets: [
      (
        field: _emailFieldKey.currentState,
        context: _emailFieldKey.currentContext,
        focusNode: _emailFocus,
      ),
    ],
    buildValue: () => ForgotPasswordFormValue(email: _emailController.text.trim()),
    onSubmit: (value) async {
      await widget.onSubmit(value);
    },
    tenFootFocusNode: _submitFocus,
  );
}
