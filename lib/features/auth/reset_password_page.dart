import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/auth/auth_form_submit_mixin.dart';
import 'package:starter/features/auth/auth_page_scaffold.dart';
import 'package:starter/features/auth/reset_password_form_value.dart';
import 'package:starter/features/auth/reset_password_presentation_state.dart';
import 'package:starter/features/auth/widgets/auth_feedback_alert.dart';
import 'package:starter/features/auth/widgets/auth_form_header.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/adaptive/app_layout_provider.dart';
import 'package:starter/shared/forms/password_form_field.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/busy_overlay.dart';
import 'package:starter/shared/widgets/forms/form_submit_button.dart';

typedef ResetPasswordSubmitCallback =
    FutureOr<void> Function(
      ResetPasswordFormValue value,
    );

class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({
    required this.onSubmit,
    required this.onLogin,
    this.presentation = const ResetPasswordPresentationState(),
    super.key,
  });

  final ResetPasswordSubmitCallback onSubmit;
  final VoidCallback onLogin;
  final ResetPasswordPresentationState presentation;

  @override
  Widget build(BuildContext context) {
    return AppLayoutScope(
      builder: (context, _) => _ResetPasswordView(
        onSubmit: onSubmit,
        onLogin: onLogin,
        presentation: presentation,
      ),
    );
  }
}

class _ResetPasswordView extends ConsumerStatefulWidget {
  const _ResetPasswordView({
    required this.onSubmit,
    required this.onLogin,
    required this.presentation,
  });

  final ResetPasswordSubmitCallback onSubmit;
  final VoidCallback onLogin;
  final ResetPasswordPresentationState presentation;

  @override
  ConsumerState<_ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends ConsumerState<_ResetPasswordView>
    with AuthFormSubmitMixin<_ResetPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _passwordFieldKey = GlobalKey<FormFieldState<String>>();
  final _confirmPasswordFieldKey = GlobalKey<FormFieldState<String>>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordFocus = FocusNode(debugLabel: 'resetPassword.newPassword');
  final _confirmPasswordFocus = FocusNode(debugLabel: 'resetPassword.confirmPassword');
  final _submitFocus = FocusNode(debugLabel: 'resetPassword.submit');

  bool get _submitting =>
      callbackSubmitting ||
      widget.presentation.status == ResetPasswordPresentationStatus.submitting;

  @override
  void initState() {
    super.initState();
    _requestFixtureFocus();
  }

  @override
  void didUpdateWidget(covariant _ResetPasswordView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.presentation.status != widget.presentation.status) {
      _requestFixtureFocus();
    }
  }

  void _requestFixtureFocus() {
    if (widget.presentation.status == ResetPasswordPresentationStatus.focused) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _passwordFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _submitFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layoutClass = ref.watch(appLayoutClassProvider);
    final form = _buildForm(context);
    final translations = context.t.auth.resetPassword;
    return BusyOverlay(
      isBusy: _submitting,
      label: translations.submitting,
      child: AuthPageScaffold(
        screenId: 'reset-password',
        layoutClass: layoutClass,
        icon: FLucideIcons.lockKeyhole,
        title: translations.title,
        body: translations.body,
        form: form,
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final translations = context.t;
    final status = widget.presentation.status;
    final invalidFixture = status == ResetPasswordPresentationStatus.invalid;
    final fieldFailureFixture = status == ResetPasswordPresentationStatus.fieldFailure;

    return AutofillGroup(
      onDisposeAction: AutofillContextAction.cancel,
      child: Form(
        key: _formKey,
        child: Column(
          key: const ValueKey('auth-reset-password-form'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthFormHeader(
              title: translations.auth.resetPassword.title,
              body: translations.auth.resetPassword.body,
              alerts: [
                ?_feedbackAlert(context),
              ],
            ),
            passwordFormField(
              activationKey: const ValueKey('auth-reset-password-new-activation'),
              fieldKey: const ValueKey('auth-reset-password-new'),
              toggleKey: const ValueKey('auth-reset-password-new-toggle'),
              label: translations.auth.resetPassword.newPassword,
              controller: _passwordController,
              focusNode: _passwordFocus,
              formFieldKey: _passwordFieldKey,
              enabled: !_submitting,
              autofocus: true,
              forceErrorText: invalidFixture ? translations.validation.passwordWeak : null,
              description: Text(
                translations.auth.common.passwordRequirements,
                key: const ValueKey('auth-reset-password-requirements'),
              ),
              autofillHints: const [AutofillHints.newPassword],
              nextFocusNode: _confirmPasswordFocus,
            ),
            const SizedBox(height: AppSpacing.lg),
            confirmPasswordFormField(
              activationKey: const ValueKey('auth-reset-password-confirm-activation'),
              fieldKey: const ValueKey('auth-reset-password-confirm'),
              toggleKey: const ValueKey('auth-reset-password-confirm-toggle'),
              label: translations.auth.common.confirmPassword,
              controller: _confirmPasswordController,
              focusNode: _confirmPasswordFocus,
              formFieldKey: _confirmPasswordFieldKey,
              matchTarget: _passwordController,
              enabled: !_submitting,
              forceErrorText: invalidFixture || fieldFailureFixture
                  ? translations.validation.passwordMismatch
                  : null,
              onSubmit: () => unawaited(_submit()),
            ),
            const SizedBox(height: AppSpacing.xl),
            FormSubmitButton(
              buttonKey: const ValueKey('auth-reset-password-submit'),
              focusNode: _submitFocus,
              onPress: () => unawaited(_submit()),
              label: translations.auth.resetPassword.submit,
              busy: _submitting,
              retainFocusOnBusy: true,
            ),
            const SizedBox(height: AppSpacing.md),
            FormSubmitButton(
              buttonKey: const ValueKey('auth-reset-password-login'),
              variant: FButtonVariant.ghost,
              onPress: widget.onLogin,
              label: translations.auth.common.returnToLogin,
              busy: _submitting,
            ),
          ],
        ),
      ),
    );
  }

  Widget? _feedbackAlert(BuildContext context) {
    final translations = context.t;
    return AuthFeedbackAlert.forStatus(
      status: widget.presentation.status,
      specFor: (status) => switch (status) {
        ResetPasswordPresentationStatus.idle ||
        ResetPasswordPresentationStatus.focused ||
        ResetPasswordPresentationStatus.submitting => null,
        ResetPasswordPresentationStatus.invalid => AuthFeedbackAlertSpec(
          key: const ValueKey('auth-reset-password-invalid'),
          variant: .destructive,
          title: Text(translations.validation.passwordWeak),
        ),
        ResetPasswordPresentationStatus.fieldFailure => AuthFeedbackAlertSpec(
          key: const ValueKey('auth-reset-password-field-failure'),
          variant: .destructive,
          title: Text(translations.validation.passwordMismatch),
        ),
        ResetPasswordPresentationStatus.globalFailure => AuthFeedbackAlertSpec(
          key: const ValueKey('auth-reset-password-global-failure'),
          variant: .destructive,
          title: Text(translations.auth.resetPassword.globalError),
        ),
        ResetPasswordPresentationStatus.success => AuthFeedbackAlertSpec(
          key: const ValueKey('auth-reset-password-success'),
          title: Text(translations.auth.resetPassword.success),
          icon: const Icon(FLucideIcons.circleCheck),
        ),
      },
    );
  }

  Future<void> _submit() {
    return submit(
      formKey: _formKey,
      orderedTargets: [
        (
          field: _passwordFieldKey.currentState,
          context: _passwordFieldKey.currentContext,
          focusNode: _passwordFocus,
        ),
        (
          field: _confirmPasswordFieldKey.currentState,
          context: _confirmPasswordFieldKey.currentContext,
          focusNode: _confirmPasswordFocus,
        ),
      ],
      buildValue: () => ResetPasswordFormValue(
        newPassword: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
      ),
      onSubmit: (value) async => widget.onSubmit(value),
      tenFootFocusNode: _submitFocus,
    );
  }
}
