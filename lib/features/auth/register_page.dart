import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/auth/auth_page_scaffold.dart';
import 'package:starter/features/auth/register_form_value.dart';
import 'package:starter/features/auth/register_presentation_state.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/adaptive/app_layout_provider.dart';
import 'package:starter/shared/adaptive/app_presentation_policy.dart';
import 'package:starter/shared/forms/form_field_reveal.dart';
import 'package:starter/shared/forms/form_validators.dart';
import 'package:starter/shared/forms/password_field_toggle.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/app_tv_editable_field.dart';
import 'package:starter/shared/widgets/busy_overlay.dart';
import 'package:starter/shared/widgets/escape_dismissible_overlay.dart';

typedef RegisterSubmitCallback = FutureOr<void> Function(RegisterFormValue value);

class RegisterPage extends StatelessWidget {
  const RegisterPage({
    required this.onSubmit,
    required this.onLogin,
    required this.onOpenTerms,
    required this.onOpenPrivacy,
    this.presentation = const RegisterPresentationState(),
    super.key,
  });

  final RegisterSubmitCallback onSubmit;
  final VoidCallback onLogin;
  final VoidCallback onOpenTerms;
  final VoidCallback onOpenPrivacy;
  final RegisterPresentationState presentation;

  @override
  Widget build(BuildContext context) {
    return AppLayoutScope(
      builder: (context, _) => _RegisterView(
        onSubmit: onSubmit,
        onLogin: onLogin,
        onOpenTerms: onOpenTerms,
        onOpenPrivacy: onOpenPrivacy,
        presentation: presentation,
      ),
    );
  }
}

class _RegisterView extends ConsumerStatefulWidget {
  const _RegisterView({
    required this.onSubmit,
    required this.onLogin,
    required this.onOpenTerms,
    required this.onOpenPrivacy,
    required this.presentation,
  });

  final RegisterSubmitCallback onSubmit;
  final VoidCallback onLogin;
  final VoidCallback onOpenTerms;
  final VoidCallback onOpenPrivacy;
  final RegisterPresentationState presentation;

  @override
  ConsumerState<_RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends ConsumerState<_RegisterView> with RestorationMixin {
  final _formKey = GlobalKey<FormState>();
  final _displayNameFieldKey = GlobalKey<FormFieldState<String>>();
  final _emailFieldKey = GlobalKey<FormFieldState<String>>();
  final _passwordFieldKey = GlobalKey<FormFieldState<String>>();
  final _confirmPasswordFieldKey = GlobalKey<FormFieldState<String>>();
  final _termsFieldKey = GlobalKey<FormFieldState<bool>>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameFocus = FocusNode(debugLabel: 'register.displayName');
  final _emailFocus = FocusNode(debugLabel: 'register.email');
  final _passwordFocus = FocusNode(debugLabel: 'register.password');
  final _confirmPasswordFocus = FocusNode(debugLabel: 'register.confirmPassword');
  final _termsFocus = FocusNode(debugLabel: 'register.acceptTerms');
  final _submitFocus = FocusNode(debugLabel: 'register.submit');
  bool _acceptTerms = false;
  bool _allowPop = false;
  bool _callbackSubmitting = false;
  bool _dirty = false;

  final RestorableString _displayNameDraft = RestorableString('');
  final RestorableString _emailDraft = RestorableString('');

  bool get _submitting =>
      _callbackSubmitting || widget.presentation.status == RegisterPresentationStatus.submitting;

  @override
  String get restorationId => 'register-view';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_displayNameDraft, 'display_name_draft');
    registerForRestoration(_emailDraft, 'email_draft');
    if (_displayNameController.text != _displayNameDraft.value) {
      _displayNameController.text = _displayNameDraft.value;
    }
    if (_emailController.text != _emailDraft.value) {
      _emailController.text = _emailDraft.value;
    }
  }

  void _syncDisplayNameDraft() {
    if (_displayNameController.text != _displayNameDraft.value) {
      _displayNameDraft.value = _displayNameController.text;
    }
  }

  void _syncEmailDraft() {
    if (_emailController.text != _emailDraft.value) {
      _emailDraft.value = _emailController.text;
    }
  }

  @override
  void initState() {
    super.initState();
    _displayNameController.addListener(_markDirty);
    _emailController.addListener(_markDirty);
    _passwordController.addListener(_markDirty);
    _confirmPasswordController.addListener(_markDirty);
    _displayNameController.addListener(_syncDisplayNameDraft);
    _emailController.addListener(_syncEmailDraft);
    _requestFixtureFocus();
  }

  @override
  void didUpdateWidget(covariant _RegisterView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.presentation.status != widget.presentation.status) {
      _requestFixtureFocus();
    }
  }

  void _requestFixtureFocus() {
    if (widget.presentation.status == RegisterPresentationStatus.focused) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _displayNameFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _displayNameController
      ..removeListener(_markDirty)
      ..removeListener(_syncDisplayNameDraft)
      ..dispose();
    _emailController
      ..removeListener(_markDirty)
      ..removeListener(_syncEmailDraft)
      ..dispose();
    _passwordController
      ..removeListener(_markDirty)
      ..dispose();
    _confirmPasswordController
      ..removeListener(_markDirty)
      ..dispose();
    _displayNameDraft.dispose();
    _emailDraft.dispose();
    _displayNameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _termsFocus.dispose();
    _submitFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layoutClass = ref.watch(appLayoutClassProvider);
    final form = _buildForm(context);
    final translations = context.t.auth.register;

    return PopScope<Object?>(
      canPop: _allowPop || !_dirty,
      onPopInvokedWithResult: _handlePop,
      child: BusyOverlay(
        isBusy: _submitting,
        label: translations.submitting,
        child: AuthPageScaffold(
          screenId: 'register',
          layoutClass: layoutClass,
          icon: FLucideIcons.userRoundPlus,
          title: translations.title,
          body: translations.body,
          form: form,
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final translations = context.t;
    final status = widget.presentation.status;
    final retainBusySubmitFocus =
        _submitting && (AppPresentationPolicy.maybeOf(context)?.isTenFoot ?? false);
    final invalidFixture = status == RegisterPresentationStatus.invalid;
    final fieldFailureFixture = status == RegisterPresentationStatus.fieldFailure;

    return AutofillGroup(
      onDisposeAction: AutofillContextAction.cancel,
      child: Form(
        key: _formKey,
        child: Column(
          key: const ValueKey('auth-register-form'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              translations.auth.register.title,
              style: context.theme.typography.display.xl2,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              translations.auth.register.body,
              style: context.theme.typography.body.md,
            ),
            if (_feedbackAlert(context) case final alert?) ...[
              const SizedBox(height: AppSpacing.xl),
              alert,
            ],
            const SizedBox(height: AppSpacing.xl),
            AppTvEditableField(
              activationKey: const ValueKey('auth-register-display-name-activation'),
              label: translations.auth.common.displayName,
              controller: _displayNameController,
              focusNode: _displayNameFocus,
              enabled: !_submitting,
              autofocus: true,
              builder: (context, editorFocusNode, completeEditing) {
                return FTextFormField(
                  key: const ValueKey('auth-register-display-name'),
                  formFieldKey: _displayNameFieldKey,
                  control: .managed(controller: _displayNameController),
                  focusNode: editorFocusNode,
                  label: Text(translations.auth.common.displayName),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  enabled: !_submitting,
                  autovalidateMode: AutovalidateMode.onUserInteractionIfError,
                  forceErrorText: invalidFixture
                      ? translations.validation.required(
                          field: translations.auth.common.displayName,
                        )
                      : null,
                  validator: (value) => validateRequired(
                    value,
                    translations.validation.required(
                      field: translations.auth.common.displayName,
                    ),
                  ),
                  onEditingComplete: () {
                    completeEditing(nextFocusNode: _emailFocus);
                  },
                  onReset: () {
                    _displayNameController.clear();
                    _displayNameFocus.unfocus();
                  },
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTvEditableField(
              activationKey: const ValueKey('auth-register-email-activation'),
              label: translations.auth.common.email,
              controller: _emailController,
              focusNode: _emailFocus,
              enabled: !_submitting,
              builder: (context, editorFocusNode, completeEditing) {
                return FTextFormField.email(
                  key: const ValueKey('auth-register-email'),
                  formFieldKey: _emailFieldKey,
                  control: .managed(controller: _emailController),
                  focusNode: editorFocusNode,
                  label: Text(translations.auth.common.email),
                  textDirection: TextDirection.ltr,
                  enabled: !_submitting,
                  autovalidateMode: AutovalidateMode.onUserInteractionIfError,
                  forceErrorText: invalidFixture || fieldFailureFixture
                      ? translations.validation.email
                      : null,
                  validator: (value) => validateEmail(
                    value,
                    requiredMessage: translations.validation.required(
                      field: translations.auth.common.email,
                    ),
                    invalidMessage: translations.validation.email,
                  ),
                  onEditingComplete: () {
                    completeEditing(nextFocusNode: _passwordFocus);
                  },
                  onReset: () {
                    _emailController.clear();
                    _emailFocus.unfocus();
                  },
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTvEditableField(
              activationKey: const ValueKey('auth-register-password-activation'),
              label: translations.auth.common.password,
              controller: _passwordController,
              focusNode: _passwordFocus,
              enabled: !_submitting,
              secure: true,
              builder: (context, editorFocusNode, completeEditing) {
                return FTextFormField.password(
                  key: const ValueKey('auth-register-password'),
                  formFieldKey: _passwordFieldKey,
                  control: .managed(controller: _passwordController),
                  focusNode: editorFocusNode,
                  label: Text(translations.auth.common.password),
                  description: _PasswordRequirements(
                    text: translations.auth.common.passwordRequirements,
                  ),
                  autofillHints: const [AutofillHints.newPassword],
                  enabled: !_submitting,
                  autovalidateMode: AutovalidateMode.onUserInteractionIfError,
                  forceErrorText: invalidFixture ? translations.validation.passwordWeak : null,
                  validator: (value) => validatePassword(
                    value,
                    requiredMessage: translations.validation.required(
                      field: translations.auth.common.password,
                    ),
                    weakMessage: translations.validation.passwordWeak,
                  ),
                  suffixBuilder: buildPasswordToggle(
                    key: const ValueKey('auth-register-password-toggle'),
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
              activationKey: const ValueKey('auth-register-confirm-password-activation'),
              label: translations.auth.common.confirmPassword,
              controller: _confirmPasswordController,
              focusNode: _confirmPasswordFocus,
              enabled: !_submitting,
              secure: true,
              builder: (context, editorFocusNode, completeEditing) {
                return FTextFormField.password(
                  key: const ValueKey('auth-register-confirm-password'),
                  formFieldKey: _confirmPasswordFieldKey,
                  control: .managed(controller: _confirmPasswordController),
                  focusNode: editorFocusNode,
                  label: Text(translations.auth.common.confirmPassword),
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  enabled: !_submitting,
                  autovalidateMode: AutovalidateMode.onUserInteractionIfError,
                  forceErrorText: invalidFixture ? translations.validation.passwordMismatch : null,
                  validator: (value) {
                    final requiredError = validateRequired(
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
                  suffixBuilder: buildPasswordToggle(
                    key: const ValueKey('auth-register-confirm-password-toggle'),
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
            const SizedBox(height: AppSpacing.lg),
            FormField<bool>(
              key: _termsFieldKey,
              initialValue: false,
              forceErrorText: invalidFixture ? translations.validation.acceptTerms : null,
              validator: (value) => value ?? false ? null : translations.validation.acceptTerms,
              onSaved: (value) => _acceptTerms = value ?? false,
              onReset: _resetTerms,
              builder: (field) => FCheckbox(
                key: const ValueKey('auth-register-accept-terms'),
                value: field.value ?? false,
                enabled: !_submitting,
                focusNode: _termsFocus,
                label: Text(translations.auth.register.acceptTerms),
                error: field.errorText == null ? null : Text(field.errorText!),
                onChange: (value) {
                  _markDirty();
                  field.didChange(value);
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                FButton(
                  key: const ValueKey('auth-register-open-terms'),
                  variant: .ghost,
                  mainAxisSize: .min,
                  onPress: _submitting ? null : widget.onOpenTerms,
                  child: Text(translations.auth.register.terms),
                ),
                FButton(
                  key: const ValueKey('auth-register-open-privacy'),
                  variant: .ghost,
                  mainAxisSize: .min,
                  onPress: _submitting ? null : widget.onOpenPrivacy,
                  child: Text(translations.auth.register.privacy),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            FButton(
              key: const ValueKey('auth-register-submit'),
              focusNode: _submitFocus,
              onPress: _submitting
                  ? retainBusySubmitFocus
                        ? () {}
                        : null
                  : () => unawaited(_submit()),
              child: Text(
                translations.auth.register.submit,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FButton(
              key: const ValueKey('auth-register-login'),
              variant: .ghost,
              onPress: _submitting ? null : widget.onLogin,
              child: Text(translations.auth.common.returnToLogin),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _feedbackAlert(BuildContext context) {
    final translations = context.t;
    return switch (widget.presentation.status) {
      RegisterPresentationStatus.idle ||
      RegisterPresentationStatus.focused ||
      RegisterPresentationStatus.submitting => null,
      RegisterPresentationStatus.invalid => FAlert(
        key: const ValueKey('auth-register-invalid'),
        variant: .destructive,
        title: Text(
          translations.validation.required(field: translations.auth.common.displayName),
        ),
      ),
      RegisterPresentationStatus.fieldFailure => FAlert(
        key: const ValueKey('auth-register-field-failure'),
        variant: .destructive,
        title: Text(translations.validation.email),
      ),
      RegisterPresentationStatus.globalFailure => FAlert(
        key: const ValueKey('auth-register-global-failure'),
        variant: .destructive,
        title: Text(translations.auth.register.globalError),
      ),
      RegisterPresentationStatus.success => FAlert(
        key: const ValueKey('auth-register-success'),
        title: Text(translations.auth.register.success),
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
      await _revealFirstInvalid(invalidFields);
      return;
    }

    form.save();
    final value = RegisterFormValue(
      displayName: _displayNameController.text,
      email: _emailController.text.trim(),
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
      acceptTerms: _acceptTerms,
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

  Future<void> _revealFirstInvalid(Set<FormFieldState<Object?>> invalidFields) async {
    await revealFirstInvalid(
      invalidFields,
      orderedTargets: [
        (
          field: _displayNameFieldKey.currentState,
          context: _displayNameFieldKey.currentContext,
          focusNode: _displayNameFocus,
        ),
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
        (
          field: _confirmPasswordFieldKey.currentState,
          context: _confirmPasswordFieldKey.currentContext,
          focusNode: _confirmPasswordFocus,
        ),
        (
          field: _termsFieldKey.currentState,
          context: _termsFieldKey.currentContext,
          focusNode: _termsFocus,
        ),
      ],
      isMounted: () => mounted,
    );
  }

  void _markDirty() {
    if (_dirty || !mounted) return;
    setState(() => _dirty = true);
  }

  void _resetTerms() {
    _acceptTerms = false;
    _termsFocus.unfocus();
    scheduleMicrotask(() {
      if (mounted) setState(() => _dirty = false);
    });
  }

  Future<void> _handlePop(bool didPop, Object? result) async {
    if (didPop || _allowPop || !_dirty || AppTvEditableField.editorHasPrimaryFocus) {
      return;
    }
    final discard = await _confirmDiscard();
    if (!discard || !mounted) return;
    setState(() => _allowPop = true);
    Navigator.of(context).pop(result);
  }

  Future<bool> _confirmDiscard() async {
    final translations = context.t;
    return await showFDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context, style, animation) => EscapeDismissibleOverlay(
            child: FDialog(
              animation: animation,
              semanticsLabel: translations.auth.register.discardTitle,
              builder: (context, style) => Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      translations.auth.register.discardTitle,
                      style: style.titleTextStyle,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      translations.auth.register.discardBody,
                      style: style.bodyTextStyle,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        FButton(
                          key: const ValueKey('auth-register-discard-stay'),
                          variant: .outline,
                          autofocus: true,
                          mainAxisSize: .min,
                          onPress: () => Navigator.of(context).pop(false),
                          child: Text(translations.auth.register.stay),
                        ),
                        FButton(
                          key: const ValueKey('auth-register-discard-confirm'),
                          variant: .destructive,
                          mainAxisSize: .min,
                          onPress: () => Navigator.of(context).pop(true),
                          child: Text(translations.auth.register.discard),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ) ??
        false;
  }
}

class _PasswordRequirements extends StatelessWidget {
  const _PasswordRequirements({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      key: const ValueKey('auth-register-password-requirements'),
      text,
    );
  }
}
