import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/auth/auth_form_submit_mixin.dart';
import 'package:starter/features/auth/auth_page_scaffold.dart';
import 'package:starter/features/auth/lockout_countdown_controller.dart';
import 'package:starter/features/auth/login_form_value.dart';
import 'package:starter/features/auth/login_presentation_state.dart';
import 'package:starter/features/auth/widgets/auth_feedback_alert.dart';
import 'package:starter/features/auth/widgets/auth_form_header.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/adaptive/app_layout_provider.dart';
import 'package:starter/shared/forms/email_form_field.dart';
import 'package:starter/shared/forms/password_form_field.dart';
import 'package:starter/shared/forms/restorable_text_controller.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/busy_overlay.dart';
import 'package:starter/shared/widgets/forms/form_submit_button.dart';

typedef LoginSubmitCallback = FutureOr<void> Function(LoginFormValue value);

class LoginPage extends StatelessWidget {
  const LoginPage({
    required this.onSubmit,
    required this.onForgotPassword,
    required this.onRegister,
    this.presentation = const LoginPresentationState(),
    super.key,
  });

  final LoginSubmitCallback onSubmit;
  final VoidCallback onForgotPassword;
  final VoidCallback onRegister;
  final LoginPresentationState presentation;

  @override
  Widget build(BuildContext context) {
    return AppLayoutScope(
      builder: (context, _) => _LoginView(
        onSubmit: onSubmit,
        onForgotPassword: onForgotPassword,
        onRegister: onRegister,
        presentation: presentation,
      ),
    );
  }
}

class _LoginView extends ConsumerStatefulWidget {
  const _LoginView({
    required this.onSubmit,
    required this.onForgotPassword,
    required this.onRegister,
    required this.presentation,
  });

  final LoginSubmitCallback onSubmit;
  final VoidCallback onForgotPassword;
  final VoidCallback onRegister;
  final LoginPresentationState presentation;

  @override
  ConsumerState<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<_LoginView>
    with
        RestorationMixin<_LoginView>,
        RestorableTextControllerBinding<_LoginView>,
        AuthFormSubmitMixin<_LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailFieldKey = GlobalKey<FormFieldState<String>>();
  final _passwordFieldKey = GlobalKey<FormFieldState<String>>();
  late final TextEditingController _emailController;
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode(debugLabel: 'login.email');
  final _passwordFocus = FocusNode(debugLabel: 'login.password');
  final RestorableString _emailDraft = RestorableString('');
  late final VoidCallback _syncEmailDraft;
  final _submitFocus = FocusNode(debugLabel: 'login.submit');
  final LockoutCountdownController _lockoutCountdown = LockoutCountdownController();
  bool _rememberMe = false;

  bool get _submitting =>
      callbackSubmitting || widget.presentation.status == LoginPresentationStatus.submitting;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _syncEmailDraft = textDraftSyncer(_emailDraft, _emailController);
    _emailController.addListener(_syncEmailDraft);
    _lockoutCountdown.syncFrom(widget.presentation.lockedSeconds);
    _requestFixtureFocus();
  }

  @override
  String get restorationId => 'login-view';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerTextDraft(_emailDraft, 'email_draft');
    if (_emailController.text != _emailDraft.value) {
      _emailController.text = _emailDraft.value;
    }
  }

  @override
  void didUpdateWidget(covariant _LoginView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.presentation.status != widget.presentation.status) {
      _requestFixtureFocus();
    }
    if (oldWidget.presentation.lockedSeconds != widget.presentation.lockedSeconds) {
      _lockoutCountdown.syncFrom(widget.presentation.lockedSeconds);
    }
  }

  void _requestFixtureFocus() {
    if (widget.presentation.status == LoginPresentationStatus.focused) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _emailFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _lockoutCountdown.dispose();
    _emailController
      ..removeListener(_syncEmailDraft)
      ..dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _emailDraft.dispose();
    _submitFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layoutClass = ref.watch(appLayoutClassProvider);
    final translations = context.t.auth.login;

    return BusyOverlay(
      isBusy: _submitting,
      label: translations.submitting,
      child: AuthPageScaffold(
        screenId: 'login',
        layoutClass: layoutClass,
        icon: FLucideIcons.shieldCheck,
        title: translations.title,
        body: translations.body,
        form: ValueListenableBuilder<int>(
          valueListenable: _lockoutCountdown,
          builder: (context, liveLockedSeconds, _) => _buildForm(context, liveLockedSeconds),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, int liveLockedSeconds) {
    final translations = context.t;
    final status = widget.presentation.status;
    final submitting = _submitting;
    final locked = status == LoginPresentationStatus.locked && liveLockedSeconds > 0;
    final invalidFixture = status == LoginPresentationStatus.invalid;
    final fieldFailureFixture = status == LoginPresentationStatus.fieldFailure;
    final enabled = !(submitting || locked);

    final attemptsAlert = AuthAttemptsRemainingAlert.maybe(
      remaining: widget.presentation.attemptsRemaining,
      locked: status == LoginPresentationStatus.locked,
      titleFor: (remaining) => Text(
        translations.auth.login.attemptsRemaining(n: remaining, count: remaining),
      ),
      alertKey: const ValueKey('auth-login-attempts-remaining'),
    );
    final feedbackAlert = AuthFeedbackAlert.forStatus<LoginPresentationStatus>(
      status: status,
      specFor: (status) => switch (status) {
        LoginPresentationStatus.idle ||
        LoginPresentationStatus.focused ||
        LoginPresentationStatus.submitting => null,
        LoginPresentationStatus.invalid => AuthFeedbackAlertSpec(
          key: const ValueKey('auth-login-invalid'),
          variant: .destructive,
          title: Text(
            translations.validation.required(field: translations.auth.common.email),
          ),
        ),
        LoginPresentationStatus.fieldFailure => AuthFeedbackAlertSpec(
          key: const ValueKey('auth-login-field-failure'),
          variant: .destructive,
          title: Text(translations.validation.email),
        ),
        LoginPresentationStatus.globalFailure => AuthFeedbackAlertSpec(
          key: const ValueKey('auth-login-global-failure'),
          variant: .destructive,
          title: Text(translations.auth.login.globalError),
        ),
        LoginPresentationStatus.success => AuthFeedbackAlertSpec(
          key: const ValueKey('auth-login-success'),
          title: Text(
            widget.presentation.successMessage ?? translations.auth.login.success,
          ),
          icon: const Icon(FLucideIcons.circleCheck),
        ),
        LoginPresentationStatus.locked => AuthFeedbackAlertSpec(
          key: const ValueKey('auth-login-locked'),
          variant: .destructive,
          title: Text(translations.auth.login.lockedTitle),
          subtitle: Text(
            translations.auth.login.lockedBody(
              n: liveLockedSeconds,
              seconds: liveLockedSeconds,
            ),
          ),
        ),
      },
    );

    final alerts = <Widget>[
      ?attemptsAlert,
      ?feedbackAlert,
    ];

    return AutofillGroup(
      onDisposeAction: AutofillContextAction.cancel,
      child: Form(
        key: _formKey,
        child: Column(
          key: const ValueKey('auth-login-form'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthFormHeader(
              title: translations.auth.login.title,
              body: translations.auth.login.body,
              alerts: alerts,
            ),
            emailFormField(
              activationKey: const ValueKey('auth-login-email-activation'),
              fieldKey: const ValueKey('auth-login-email'),
              label: translations.auth.common.email,
              controller: _emailController,
              focusNode: _emailFocus,
              formFieldKey: _emailFieldKey,
              nextFocusNode: _passwordFocus,
              enabled: enabled,
              autofocus: true,
              forceErrorText: invalidFixture || fieldFailureFixture
                  ? translations.validation.email
                  : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            passwordFormField(
              activationKey: const ValueKey('auth-login-password-activation'),
              fieldKey: const ValueKey('auth-login-password'),
              toggleKey: const ValueKey('auth-login-password-toggle'),
              label: translations.auth.common.password,
              controller: _passwordController,
              focusNode: _passwordFocus,
              formFieldKey: _passwordFieldKey,
              enabled: enabled,
              forceErrorText: invalidFixture ? translations.validation.passwordWeak : null,
              textInputAction: TextInputAction.done,
              onSubmit: () => unawaited(_submit()),
            ),
            const SizedBox(height: AppSpacing.lg),
            FormField<bool>(
              initialValue: false,
              onSaved: (value) => _rememberMe = value ?? false,
              onReset: () => _rememberMe = false,
              builder: (field) => MergeSemantics(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: FCheckbox(
                    key: const ValueKey('auth-login-remember'),
                    value: field.value ?? false,
                    enabled: enabled,
                    label: Text(translations.auth.login.rememberMe),
                    error: field.errorText == null ? null : Text(field.errorText!),
                    onChange: field.didChange,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FButton(
              key: const ValueKey('auth-login-submit'),
              focusNode: _submitFocus,
              onPress: locked
                  ? null
                  : submitting
                  ? () {}
                  : () => unawaited(_submit()),
              builder: (_, _, _, _, _, child) => Flexible(child: child!),
              child: Text(
                translations.auth.login.submit,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                FormSubmitButton(
                  buttonKey: const ValueKey('auth-login-forgot-password'),
                  variant: FButtonVariant.ghost,
                  mainAxisSize: MainAxisSize.min,
                  busy: submitting,
                  onPress: widget.onForgotPassword,
                  label: translations.auth.login.forgotPassword,
                ),
                FormSubmitButton(
                  buttonKey: const ValueKey('auth-login-register'),
                  variant: FButtonVariant.ghost,
                  mainAxisSize: MainAxisSize.min,
                  busy: submitting,
                  onPress: widget.onRegister,
                  label: translations.auth.login.register,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() => submit(
    formKey: _formKey,
    orderedTargets: [
      (
        field: _emailFieldKey.currentState,
        context: _emailFieldKey.currentContext,
        focusNode: _emailFocus,
      ),
      (
        field: _passwordFieldKey.currentState,
        context: _passwordFieldKey.currentContext,
        focusNode: _passwordFocus,
      ),
    ],
    buildValue: () => LoginFormValue(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      rememberMe: _rememberMe,
    ),
    onSubmit: (value) async => widget.onSubmit(value),
    tenFootFocusNode: _submitFocus,
  );
}
