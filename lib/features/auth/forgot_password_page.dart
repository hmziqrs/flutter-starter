import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/auth/auth_form_support.dart';
import 'package:starter/features/auth/auth_page_scaffold.dart';
import 'package:starter/features/auth/forgot_password_form_value.dart';
import 'package:starter/features/auth/forgot_password_presentation_state.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/adaptive/app_layout_provider.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/busy_overlay.dart';

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

class _ForgotPasswordViewState extends ConsumerState<_ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _emailFieldKey = GlobalKey<FormFieldState<String>>();
  final _emailController = TextEditingController();
  final _emailFocus = FocusNode(debugLabel: 'forgotPassword.email');
  bool _callbackSubmitting = false;

  bool get _submitting =>
      _callbackSubmitting ||
      widget.presentation.status == ForgotPasswordPresentationStatus.submitting;

  @override
  void initState() {
    super.initState();
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
    _emailController.dispose();
    _emailFocus.dispose();
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

    return AutofillGroup(
      onDisposeAction: AutofillContextAction.cancel,
      child: Form(
        key: _formKey,
        child: Column(
          key: const ValueKey('auth-forgot-password-form'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              translations.auth.forgotPassword.title,
              style: context.theme.typography.display.xl2,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              translations.auth.forgotPassword.body,
              style: context.theme.typography.body.md,
            ),
            if (_feedbackAlert(context) case final alert?) ...[
              const SizedBox(height: AppSpacing.xl),
              alert,
            ],
            const SizedBox(height: AppSpacing.xl),
            FTextFormField.email(
              key: const ValueKey('auth-forgot-password-email'),
              formFieldKey: _emailFieldKey,
              control: .managed(controller: _emailController),
              focusNode: _emailFocus,
              label: Text(translations.auth.common.email),
              textDirection: TextDirection.ltr,
              autofillHints: const [AutofillHints.username, AutofillHints.email],
              textInputAction: TextInputAction.done,
              enabled: !_submitting,
              autovalidateMode: AutovalidateMode.onUserInteractionIfError,
              forceErrorText: forceEmailError ? translations.validation.email : null,
              validator: (value) => validateAuthEmail(
                value,
                requiredMessage: translations.validation.required(
                  field: translations.auth.common.email,
                ),
                invalidMessage: translations.validation.email,
              ),
              onSubmit: (_) => unawaited(_submit()),
              onReset: () {
                _emailController.clear();
                _emailFocus.unfocus();
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            FButton(
              key: const ValueKey('auth-forgot-password-submit'),
              onPress: _submitting ? null : () => unawaited(_submit()),
              builder: (_, _, _, _, _, child) => Flexible(child: child!),
              child: Text(
                translations.auth.forgotPassword.submit,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FButton(
              key: const ValueKey('auth-forgot-password-login'),
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
      ForgotPasswordPresentationStatus.idle ||
      ForgotPasswordPresentationStatus.focused ||
      ForgotPasswordPresentationStatus.submitting => null,
      ForgotPasswordPresentationStatus.invalid => FAlert(
        key: const ValueKey('auth-forgot-password-invalid'),
        variant: .destructive,
        title: Text(translations.validation.email),
      ),
      ForgotPasswordPresentationStatus.fieldFailure => FAlert(
        key: const ValueKey('auth-forgot-password-field-failure'),
        variant: .destructive,
        title: Text(translations.validation.email),
      ),
      ForgotPasswordPresentationStatus.globalFailure => FAlert(
        key: const ValueKey('auth-forgot-password-global-failure'),
        variant: .destructive,
        title: Text(translations.common.notConnected),
      ),
      ForgotPasswordPresentationStatus.success => FAlert(
        key: const ValueKey('auth-forgot-password-success'),
        title: Text(translations.auth.forgotPassword.success),
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
            field: _emailFieldKey.currentState,
            context: _emailFieldKey.currentContext,
            focusNode: _emailFocus,
          ),
        ],
        isMounted: () => mounted,
      );
      return;
    }

    form.save();
    final value = ForgotPasswordFormValue(email: _emailController.text.trim());
    setState(() => _callbackSubmitting = true);
    TextInput.finishAutofillContext(shouldSave: false);
    try {
      await widget.onSubmit(value);
    } finally {
      if (mounted) setState(() => _callbackSubmitting = false);
    }
  }
}
