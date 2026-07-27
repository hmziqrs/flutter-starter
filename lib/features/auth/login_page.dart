import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/auth/auth_form_support.dart';
import 'package:starter/features/auth/auth_page_scaffold.dart';
import 'package:starter/features/auth/login_form_value.dart';
import 'package:starter/features/auth/login_presentation_state.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/adaptive/app_layout_provider.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/busy_overlay.dart';

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

class _LoginViewState extends ConsumerState<_LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailFieldKey = GlobalKey<FormFieldState<String>>();
  final _passwordFieldKey = GlobalKey<FormFieldState<String>>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode(debugLabel: 'login.email');
  final _passwordFocus = FocusNode(debugLabel: 'login.password');
  bool _callbackSubmitting = false;
  bool _rememberMe = false;

  // Rate-limit countdown (auth-ratelimit). Drives the live lockout seconds
  // decremented by a 1s Timer.periodic; the submit gate is OR-ed with _locked.
  Timer? _countdownTimer;
  int _liveLockedSeconds = 0;

  bool get _submitting =>
      _callbackSubmitting || widget.presentation.status == LoginPresentationStatus.submitting;

  /// True while a rate-limit lockout is active. Independent of any animation so
  /// the non-animated fallback still disables submit.
  bool get _locked =>
      widget.presentation.status == LoginPresentationStatus.locked && _liveLockedSeconds > 0;

  @override
  void initState() {
    super.initState();
    _liveLockedSeconds = widget.presentation.lockedSeconds;
    _requestFixtureFocus();
    _startLockoutCountdownIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _LoginView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.presentation.status != widget.presentation.status) {
      _requestFixtureFocus();
    }
    if (oldWidget.presentation.lockedSeconds != widget.presentation.lockedSeconds) {
      _liveLockedSeconds = widget.presentation.lockedSeconds;
      _startLockoutCountdownIfNeeded();
    }
  }

  void _requestFixtureFocus() {
    if (widget.presentation.status == LoginPresentationStatus.focused) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _emailFocus.requestFocus();
      });
    }
  }

  void _startLockoutCountdownIfNeeded() {
    _countdownTimer?.cancel();
    if (_liveLockedSeconds <= 0) {
      return;
    }
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_liveLockedSeconds > 0) _liveLockedSeconds -= 1;
        if (_liveLockedSeconds <= 0) timer.cancel();
      });
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layoutClass = ref.watch(appLayoutClassProvider);
    final form = _buildForm(context);
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
        form: form,
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final translations = context.t;
    final status = widget.presentation.status;
    final invalidFixture = status == LoginPresentationStatus.invalid;
    final fieldFailureFixture = status == LoginPresentationStatus.fieldFailure;

    return AutofillGroup(
      onDisposeAction: AutofillContextAction.cancel,
      child: Form(
        key: _formKey,
        child: Column(
          key: const ValueKey('auth-login-form'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              translations.auth.login.title,
              style: context.theme.typography.display.xl2,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              translations.auth.login.body,
              style: context.theme.typography.body.md,
            ),
            if (_attemptsRemainingAlert(context) case final alert?) ...[
              const SizedBox(height: AppSpacing.xl),
              alert,
            ],
            if (_feedbackAlert(context) case final alert?) ...[
              const SizedBox(height: AppSpacing.xl),
              alert,
            ],
            const SizedBox(height: AppSpacing.xl),
            FTextFormField.email(
              key: const ValueKey('auth-login-email'),
              formFieldKey: _emailFieldKey,
              control: .managed(controller: _emailController),
              focusNode: _emailFocus,
              label: Text(translations.auth.common.email),
              textDirection: TextDirection.ltr,
              autofillHints: const [AutofillHints.username, AutofillHints.email],
              enabled: !(_submitting || _locked),
              autovalidateMode: AutovalidateMode.onUserInteractionIfError,
              forceErrorText: invalidFixture || fieldFailureFixture
                  ? translations.validation.email
                  : null,
              validator: (value) => validateAuthEmail(
                value,
                requiredMessage: translations.validation.required(
                  field: translations.auth.common.email,
                ),
                invalidMessage: translations.validation.email,
              ),
              onEditingComplete: _passwordFocus.requestFocus,
              onReset: () {
                _emailController.clear();
                _emailFocus.unfocus();
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            FTextFormField.password(
              key: const ValueKey('auth-login-password'),
              formFieldKey: _passwordFieldKey,
              control: .managed(controller: _passwordController),
              focusNode: _passwordFocus,
              label: Text(translations.auth.common.password),
              textInputAction: TextInputAction.done,
              enabled: !(_submitting || _locked),
              autovalidateMode: AutovalidateMode.onUserInteractionIfError,
              forceErrorText: invalidFixture ? translations.validation.passwordWeak : null,
              validator: (value) => validateAuthPassword(
                value,
                requiredMessage: translations.validation.required(
                  field: translations.auth.common.password,
                ),
                weakMessage: translations.validation.passwordWeak,
              ),
              suffixBuilder: buildAuthPasswordToggle(
                key: const ValueKey('auth-login-password-toggle'),
              ),
              onSubmit: (_) => unawaited(_submit()),
              onReset: () {
                _passwordController.clear();
                _passwordFocus.unfocus();
              },
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
                    enabled: !(_submitting || _locked),
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
              onPress: (_submitting || _locked) ? null : () => unawaited(_submit()),
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
                FButton(
                  key: const ValueKey('auth-login-forgot-password'),
                  variant: .ghost,
                  mainAxisSize: .min,
                  builder: (_, _, _, _, _, child) => Flexible(child: child!),
                  onPress: _submitting ? null : widget.onForgotPassword,
                  child: Text(
                    translations.auth.login.forgotPassword,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                FButton(
                  key: const ValueKey('auth-login-register'),
                  variant: .ghost,
                  mainAxisSize: .min,
                  builder: (_, _, _, _, _, child) => Flexible(child: child!),
                  onPress: _submitting ? null : widget.onRegister,
                  child: Text(
                    translations.auth.login.register,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget? _feedbackAlert(BuildContext context) {
    final translations = context.t;
    return switch (widget.presentation.status) {
      LoginPresentationStatus.idle ||
      LoginPresentationStatus.focused ||
      LoginPresentationStatus.submitting => null,
      LoginPresentationStatus.invalid => FAlert(
        key: const ValueKey('auth-login-invalid'),
        variant: .destructive,
        title: Text(
          translations.validation.required(field: translations.auth.common.email),
        ),
      ),
      LoginPresentationStatus.fieldFailure => FAlert(
        key: const ValueKey('auth-login-field-failure'),
        variant: .destructive,
        title: Text(translations.validation.email),
      ),
      LoginPresentationStatus.globalFailure => FAlert(
        key: const ValueKey('auth-login-global-failure'),
        variant: .destructive,
        title: Text(translations.auth.login.globalError),
      ),
      LoginPresentationStatus.success => FAlert(
        key: const ValueKey('auth-login-success'),
        title: Text(widget.presentation.successMessage ?? translations.auth.login.success),
        icon: const Icon(FLucideIcons.circleCheck),
      ),
      LoginPresentationStatus.locked => FAlert(
        key: const ValueKey('auth-login-locked'),
        variant: .destructive,
        title: Text(translations.auth.login.lockedTitle),
        subtitle: Text(
          translations.auth.login.lockedBody(n: _liveLockedSeconds, seconds: _liveLockedSeconds),
        ),
      ),
    };
  }

  /// Non-destructive "attempts remaining" notice, shown while the user still
  /// has free attempts before the next lockout. Suppressed once locked (the
  /// destructive [_feedbackAlert] carries the countdown instead).
  Widget? _attemptsRemainingAlert(BuildContext context) {
    final remaining = widget.presentation.attemptsRemaining;
    if (remaining <= 0 || widget.presentation.status == LoginPresentationStatus.locked) {
      return null;
    }
    return FAlert(
      key: const ValueKey('auth-login-attempts-remaining'),
      title: Text(context.t.auth.login.attemptsRemaining(n: remaining, count: remaining)),
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final form = _formKey.currentState;
    if (form == null) return;

    final invalidFields = form.validateGranularly();
    if (invalidFields.isNotEmpty) {
      await _revealFirstInvalid(invalidFields);
      return;
    }

    form.save();
    final value = LoginFormValue(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      rememberMe: _rememberMe,
    );

    setState(() => _callbackSubmitting = true);
    TextInput.finishAutofillContext(shouldSave: false);
    try {
      await widget.onSubmit(value);
    } finally {
      if (mounted) setState(() => _callbackSubmitting = false);
    }
  }

  Future<void> _revealFirstInvalid(Set<FormFieldState<Object?>> invalidFields) async {
    await revealFirstAuthInvalid(
      invalidFields,
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
      isMounted: () => mounted,
    );
  }
}
