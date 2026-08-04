import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/auth/auth_form_submit_mixin.dart';
import 'package:starter/features/auth/auth_page_scaffold.dart';
import 'package:starter/features/auth/register_form_value.dart';
import 'package:starter/features/auth/register_presentation_state.dart';
import 'package:starter/features/auth/widgets/auth_feedback_alert.dart';
import 'package:starter/features/auth/widgets/auth_form_header.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/adaptive/app_layout_provider.dart';
import 'package:starter/shared/forms/email_form_field.dart';
import 'package:starter/shared/forms/form_field_reveal.dart';
import 'package:starter/shared/forms/form_validators.dart';
import 'package:starter/shared/forms/password_form_field.dart';
import 'package:starter/shared/forms/restorable_text_controller.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/app_tv_editable_field.dart';
import 'package:starter/shared/widgets/busy_overlay.dart';
import 'package:starter/shared/widgets/feedback/app_confirmation_dialog.dart';
import 'package:starter/shared/widgets/forms/form_submit_button.dart';

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

class _RegisterViewState extends ConsumerState<_RegisterView>
    with
        RestorationMixin<_RegisterView>,
        RestorableTextControllerBinding<_RegisterView>,
        AuthFormSubmitMixin<_RegisterView> {
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
  bool _dirty = false;

  final RestorableString _displayNameDraft = RestorableString('');
  final RestorableString _emailDraft = RestorableString('');
  // Created in initState; stored so dispose can remove the listener.
  late final VoidCallback _syncDisplayNameDraft;
  late final VoidCallback _syncEmailDraft;

  bool get _submitting =>
      callbackSubmitting || widget.presentation.status == RegisterPresentationStatus.submitting;

  @override
  String get restorationId => 'register-view';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerTextDraft(_displayNameDraft, 'display_name_draft');
    registerTextDraft(_emailDraft, 'email_draft');
    if (_displayNameController.text != _displayNameDraft.value) {
      _displayNameController.text = _displayNameDraft.value;
    }
    if (_emailController.text != _emailDraft.value) {
      _emailController.text = _emailDraft.value;
    }
  }

  @override
  void initState() {
    super.initState();
    _syncDisplayNameDraft = textDraftSyncer(_displayNameDraft, _displayNameController);
    _syncEmailDraft = textDraftSyncer(_emailDraft, _emailController);
    _displayNameController
      ..addListener(_markDirty)
      ..addListener(_syncDisplayNameDraft);
    _emailController
      ..addListener(_markDirty)
      ..addListener(_syncEmailDraft);
    _passwordController.addListener(_markDirty);
    _confirmPasswordController.addListener(_markDirty);
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
    final invalidFixture = status == RegisterPresentationStatus.invalid;
    final fieldFailureFixture = status == RegisterPresentationStatus.fieldFailure;
    final feedbackAlert = _feedbackAlert(context);

    return AutofillGroup(
      onDisposeAction: AutofillContextAction.cancel,
      child: Form(
        key: _formKey,
        child: Column(
          key: const ValueKey('auth-register-form'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthFormHeader(
              title: translations.auth.register.title,
              body: translations.auth.register.body,
              alerts: [?feedbackAlert],
            ),
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
            emailFormField(
              activationKey: const ValueKey('auth-register-email-activation'),
              fieldKey: const ValueKey('auth-register-email'),
              label: translations.auth.common.email,
              controller: _emailController,
              focusNode: _emailFocus,
              formFieldKey: _emailFieldKey,
              enabled: !_submitting,
              forceErrorText: invalidFixture || fieldFailureFixture
                  ? translations.validation.email
                  : null,
              nextFocusNode: _passwordFocus,
            ),
            const SizedBox(height: AppSpacing.lg),
            passwordFormField(
              activationKey: const ValueKey('auth-register-password-activation'),
              fieldKey: const ValueKey('auth-register-password'),
              toggleKey: const ValueKey('auth-register-password-toggle'),
              label: translations.auth.common.password,
              controller: _passwordController,
              focusNode: _passwordFocus,
              formFieldKey: _passwordFieldKey,
              enabled: !_submitting,
              forceErrorText: invalidFixture ? translations.validation.passwordWeak : null,
              description: _PasswordRequirements(
                text: translations.auth.common.passwordRequirements,
              ),
              autofillHints: const [AutofillHints.newPassword],
              nextFocusNode: _confirmPasswordFocus,
            ),
            const SizedBox(height: AppSpacing.lg),
            confirmPasswordFormField(
              activationKey: const ValueKey('auth-register-confirm-password-activation'),
              fieldKey: const ValueKey('auth-register-confirm-password'),
              toggleKey: const ValueKey('auth-register-confirm-password-toggle'),
              label: translations.auth.common.confirmPassword,
              controller: _confirmPasswordController,
              focusNode: _confirmPasswordFocus,
              formFieldKey: _confirmPasswordFieldKey,
              matchTarget: _passwordController,
              enabled: !_submitting,
              forceErrorText: invalidFixture ? translations.validation.passwordMismatch : null,
              onSubmit: () => unawaited(_submit()),
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
                FormSubmitButton(
                  buttonKey: const ValueKey('auth-register-open-terms'),
                  variant: FButtonVariant.ghost,
                  mainAxisSize: MainAxisSize.min,
                  onPress: widget.onOpenTerms,
                  label: translations.auth.register.terms,
                  busy: _submitting,
                ),
                FormSubmitButton(
                  buttonKey: const ValueKey('auth-register-open-privacy'),
                  variant: FButtonVariant.ghost,
                  mainAxisSize: MainAxisSize.min,
                  onPress: widget.onOpenPrivacy,
                  label: translations.auth.register.privacy,
                  busy: _submitting,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            FormSubmitButton(
              buttonKey: const ValueKey('auth-register-submit'),
              focusNode: _submitFocus,
              onPress: () => unawaited(_submit()),
              label: translations.auth.register.submit,
              busy: _submitting,
              retainFocusOnBusy: true,
            ),
            const SizedBox(height: AppSpacing.md),
            FormSubmitButton(
              buttonKey: const ValueKey('auth-register-login'),
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
    return AuthFeedbackAlert.forStatus<RegisterPresentationStatus>(
      status: widget.presentation.status,
      specFor: (status) => switch (status) {
        RegisterPresentationStatus.idle ||
        RegisterPresentationStatus.focused ||
        RegisterPresentationStatus.submitting => null,
        RegisterPresentationStatus.invalid => AuthFeedbackAlertSpec(
          key: const ValueKey('auth-register-invalid'),
          variant: FAlertVariant.destructive,
          title: Text(
            translations.validation.required(field: translations.auth.common.displayName),
          ),
        ),
        RegisterPresentationStatus.fieldFailure => AuthFeedbackAlertSpec(
          key: const ValueKey('auth-register-field-failure'),
          variant: FAlertVariant.destructive,
          title: Text(translations.validation.email),
        ),
        RegisterPresentationStatus.globalFailure => AuthFeedbackAlertSpec(
          key: const ValueKey('auth-register-global-failure'),
          variant: FAlertVariant.destructive,
          title: Text(translations.auth.register.globalError),
        ),
        RegisterPresentationStatus.success => AuthFeedbackAlertSpec(
          key: const ValueKey('auth-register-success'),
          title: Text(translations.auth.register.success),
          icon: const Icon(FLucideIcons.circleCheck),
        ),
      },
    );
  }

  Future<void> _submit() => submit<RegisterFormValue>(
    formKey: _formKey,
    orderedTargets: <InvalidFieldTarget>[
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
    buildValue: () => RegisterFormValue(
      displayName: _displayNameController.text,
      email: _emailController.text.trim(),
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
      acceptTerms: _acceptTerms,
    ),
    onSubmit: (value) async {
      await widget.onSubmit(value);
    },
    tenFootFocusNode: _submitFocus,
  );

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
    return await AppConfirmationDialog.show(
          context,
          intent: ConfirmationIntent.destroy,
          title: translations.auth.register.discardTitle,
          body: translations.auth.register.discardBody,
          cancelLabel: translations.auth.register.stay,
          confirmLabel: translations.auth.register.discard,
          cancelKey: const ValueKey('auth-register-discard-stay'),
          actionKey: const ValueKey('auth-register-discard-confirm'),
          autofocusCancel: true,
          titleBodySpacing: AppSpacing.md,
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
