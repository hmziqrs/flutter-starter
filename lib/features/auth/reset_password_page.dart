import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/auth/auth_form_support.dart';
import 'package:starter/features/auth/auth_page_scaffold.dart';
import 'package:starter/features/auth/reset_password_form_value.dart';
import 'package:starter/features/auth/reset_password_presentation_state.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/adaptive/app_layout_provider.dart';
import 'package:starter/shared/adaptive/app_presentation_policy.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/app_tv_editable_field.dart';
import 'package:starter/shared/widgets/busy_overlay.dart';

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

class _ResetPasswordViewState extends ConsumerState<_ResetPasswordView> with RestorationMixin {
  final _formKey = GlobalKey<FormState>();
  final _passwordFieldKey = GlobalKey<FormFieldState<String>>();
  final _confirmPasswordFieldKey = GlobalKey<FormFieldState<String>>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordFocus = FocusNode(debugLabel: 'resetPassword.newPassword');
  final _confirmPasswordFocus = FocusNode(debugLabel: 'resetPassword.confirmPassword');
  final _submitFocus = FocusNode(debugLabel: 'resetPassword.submit');
  bool _callbackSubmitting = false;

  bool get _submitting =>
      _callbackSubmitting ||
      widget.presentation.status == ResetPasswordPresentationStatus.submitting;

  @override
  String get restorationId => 'reset-password-view';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    // This page participates in the restoration tree (state-restoration
    // contract) but registers NO restorable properties: both fields are new
    // passwords, and secrets never participate in restoration (mirrors the
    // login_page rule). The user re-types a new password after a process death
    // rather than having a credential draft persisted.
  }

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
    final isTenFoot = AppPresentationPolicy.maybeOf(context)?.isTenFoot ?? false;
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
            Text(
              translations.auth.resetPassword.title,
              style: context.theme.typography.display.xl2,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              translations.auth.resetPassword.body,
              style: context.theme.typography.body.md,
            ),
            if (_feedbackAlert(context) case final alert?) ...[
              const SizedBox(height: AppSpacing.xl),
              alert,
            ],
            const SizedBox(height: AppSpacing.xl),
            AppTvEditableField(
              activationKey: const ValueKey('auth-reset-password-new-activation'),
              label: translations.auth.resetPassword.newPassword,
              controller: _passwordController,
              focusNode: _passwordFocus,
              enabled: !_submitting,
              secure: true,
              autofocus: true,
              builder: (context, editorFocusNode, completeEditing) {
                return FTextFormField.password(
                  key: const ValueKey('auth-reset-password-new'),
                  formFieldKey: _passwordFieldKey,
                  control: .managed(controller: _passwordController),
                  focusNode: editorFocusNode,
                  label: Text(translations.auth.resetPassword.newPassword),
                  description: Text(
                    translations.auth.common.passwordRequirements,
                    key: const ValueKey('auth-reset-password-requirements'),
                  ),
                  autofillHints: const [AutofillHints.newPassword],
                  enabled: !_submitting,
                  autovalidateMode: AutovalidateMode.onUserInteractionIfError,
                  forceErrorText: invalidFixture ? translations.validation.passwordWeak : null,
                  validator: (value) => validateAuthPassword(
                    value,
                    requiredMessage: translations.validation.required(
                      field: translations.auth.resetPassword.newPassword,
                    ),
                    weakMessage: translations.validation.passwordWeak,
                  ),
                  suffixBuilder: buildAuthPasswordToggle(
                    key: const ValueKey('auth-reset-password-new-toggle'),
                  ),
                  onEditingComplete: () {
                    completeEditing(nextFocusNode: _confirmPasswordFocus);
                  },
                  onReset: () {
                    _passwordController.clear();
                    _passwordFocus.unfocus();
                  },
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTvEditableField(
              activationKey: const ValueKey('auth-reset-password-confirm-activation'),
              label: translations.auth.common.confirmPassword,
              controller: _confirmPasswordController,
              focusNode: _confirmPasswordFocus,
              enabled: !_submitting,
              secure: true,
              builder: (context, editorFocusNode, completeEditing) {
                return FTextFormField.password(
                  key: const ValueKey('auth-reset-password-confirm'),
                  formFieldKey: _confirmPasswordFieldKey,
                  control: .managed(controller: _confirmPasswordController),
                  focusNode: editorFocusNode,
                  label: Text(translations.auth.common.confirmPassword),
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  enabled: !_submitting,
                  autovalidateMode: AutovalidateMode.onUserInteractionIfError,
                  forceErrorText: invalidFixture || fieldFailureFixture
                      ? translations.validation.passwordMismatch
                      : null,
                  validator: (value) {
                    final requiredError = validateAuthRequired(
                      value,
                      translations.validation.required(
                        field: translations.auth.common.confirmPassword,
                      ),
                    );
                    if (requiredError != null) return requiredError;
                    if (value != _passwordController.text) {
                      return translations.validation.passwordMismatch;
                    }
                    return null;
                  },
                  suffixBuilder: buildAuthPasswordToggle(
                    key: const ValueKey('auth-reset-password-confirm-toggle'),
                  ),
                  onSubmit: (_) {
                    completeEditing();
                    unawaited(_submit());
                  },
                  onReset: () {
                    _confirmPasswordController.clear();
                    _confirmPasswordFocus.unfocus();
                  },
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            FButton(
              key: const ValueKey('auth-reset-password-submit'),
              focusNode: _submitFocus,
              onPress: _submitting
                  ? isTenFoot
                        ? () {}
                        : null
                  : () => unawaited(_submit()),
              builder: (_, _, _, _, _, child) => Flexible(child: child!),
              child: Text(
                translations.auth.resetPassword.submit,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FButton(
              key: const ValueKey('auth-reset-password-login'),
              variant: .ghost,
              onPress: _submitting ? null : widget.onLogin,
              builder: (_, _, _, _, _, child) => Flexible(child: child!),
              child: Text(
                translations.auth.common.returnToLogin,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _feedbackAlert(BuildContext context) {
    final translations = context.t;
    return switch (widget.presentation.status) {
      ResetPasswordPresentationStatus.idle ||
      ResetPasswordPresentationStatus.focused ||
      ResetPasswordPresentationStatus.submitting => null,
      ResetPasswordPresentationStatus.invalid => FAlert(
        key: const ValueKey('auth-reset-password-invalid'),
        variant: .destructive,
        title: Text(translations.validation.passwordWeak),
      ),
      ResetPasswordPresentationStatus.fieldFailure => FAlert(
        key: const ValueKey('auth-reset-password-field-failure'),
        variant: .destructive,
        title: Text(translations.validation.passwordMismatch),
      ),
      ResetPasswordPresentationStatus.globalFailure => FAlert(
        key: const ValueKey('auth-reset-password-global-failure'),
        variant: .destructive,
        title: Text(translations.auth.resetPassword.globalError),
      ),
      ResetPasswordPresentationStatus.success => FAlert(
        key: const ValueKey('auth-reset-password-success'),
        title: Text(translations.auth.resetPassword.success),
        icon: const Icon(FLucideIcons.circleCheck),
      ),
    };
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final form = _formKey.currentState;
    if (form == null) return;
    final invalidFields = form.validateGranularly();
    if (invalidFields.isNotEmpty) {
      await revealFirstAuthInvalid(
        invalidFields,
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
        isMounted: () => mounted,
      );
      return;
    }

    form.save();
    final value = ResetPasswordFormValue(
      newPassword: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );
    if (AppPresentationPolicy.maybeOf(context)?.isTenFoot ?? false) {
      _submitFocus.requestFocus();
    }
    setState(() => _callbackSubmitting = true);
    TextInput.finishAutofillContext(shouldSave: false);
    try {
      await widget.onSubmit(value);
    } finally {
      if (mounted) setState(() => _callbackSubmitting = false);
    }
  }
}
