import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:starter/app/routing/otp_purpose.dart';
import 'package:starter/features/auth/auth_form_submit_mixin.dart';
import 'package:starter/features/auth/auth_page_scaffold.dart';
import 'package:starter/features/auth/lockout_countdown_controller.dart';
import 'package:starter/features/auth/otp_form_value.dart';
import 'package:starter/features/auth/otp_presentation_state.dart';
import 'package:starter/features/auth/widgets/auth_feedback_alert.dart';
import 'package:starter/features/auth/widgets/auth_form_header.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/adaptive/app_layout_provider.dart';
import 'package:starter/shared/adaptive/app_presentation_policy.dart';
import 'package:starter/shared/forms/restorable_text_controller.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/app_tv_editable_field.dart';
import 'package:starter/shared/widgets/busy_overlay.dart';
import 'package:starter/shared/widgets/forms/form_submit_button.dart';

typedef OtpSubmitCallback = FutureOr<void> Function(OtpFormValue value);
typedef OtpResendCallback = FutureOr<void> Function();

class OtpPage extends StatelessWidget {
  const OtpPage({
    required this.purpose,
    required this.onSubmit,
    required this.onResend,
    this.presentation = const OtpPresentationState(),
    super.key,
  });

  final OtpPurpose purpose;
  final OtpSubmitCallback onSubmit;
  final OtpResendCallback onResend;
  final OtpPresentationState presentation;

  @override
  Widget build(BuildContext context) {
    return AppLayoutScope(
      builder: (context, _) => _OtpView(
        purpose: purpose,
        onSubmit: onSubmit,
        onResend: onResend,
        presentation: presentation,
      ),
    );
  }
}

class _OtpView extends ConsumerStatefulWidget {
  const _OtpView({
    required this.purpose,
    required this.onSubmit,
    required this.onResend,
    required this.presentation,
  });

  final OtpPurpose purpose;
  final OtpSubmitCallback onSubmit;
  final OtpResendCallback onResend;
  final OtpPresentationState presentation;

  @override
  ConsumerState<_OtpView> createState() => _OtpViewState();
}

class _OtpViewState extends ConsumerState<_OtpView>
    with
        RestorationMixin,
        AuthFormSubmitMixin<_OtpView>,
        RestorableTextControllerBinding<_OtpView> {
  final _formKey = GlobalKey<FormState>();
  final _otpFieldKey = GlobalKey<FormFieldState<String>>();
  final _otpFocus = FocusNode(debugLabel: 'otp.code');
  final _submitFocus = FocusNode(debugLabel: 'otp.submit');
  final _resendFocus = FocusNode(debugLabel: 'otp.resend');
  late final FOtpController _otpController = FOtpController(
    value: TextEditingValue(
      text: _fixtureCode(widget.presentation.status),
      selection: TextSelection.collapsed(
        offset: _fixtureCode(widget.presentation.status).length,
      ),
    ),
  );
  bool _callbackResending = false;
  String _savedCode = '';

  final RestorableString _codeDraft = RestorableString('');

  late final LockoutCountdownController _lockout = LockoutCountdownController();
  late final VoidCallback _syncCodeDraft;

  bool get _submitting =>
      callbackSubmitting || widget.presentation.status == OtpPresentationStatus.submitting;

  bool get _resending =>
      _callbackResending || widget.presentation.status == OtpPresentationStatus.resending;

  bool get _locked =>
      widget.presentation.status == OtpPresentationStatus.locked && _lockout.remainingSeconds > 0;

  bool get _resendBlocked => _resending || widget.presentation.resendSeconds > 0 || _locked;

  @override
  String get restorationId => 'otp-view';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerTextDraft(_codeDraft, 'code_draft');
    if (_codeDraft.value.isNotEmpty) {
      _otpController.value = TextEditingValue(
        text: _codeDraft.value,
        selection: TextSelection.collapsed(offset: _codeDraft.value.length),
      );
      _savedCode = _codeDraft.value;
    }
  }

  @override
  void initState() {
    super.initState();
    _syncCodeDraft = textDraftSyncer(_codeDraft, _otpController);
    _otpController.addListener(_syncCodeDraft);
    _lockout
      ..addListener(_onLockoutChanged)
      ..syncFrom(widget.presentation.lockedSeconds);
  }

  void _onLockoutChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant _OtpView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.presentation.lockedSeconds != widget.presentation.lockedSeconds) {
      _lockout.syncFrom(widget.presentation.lockedSeconds);
    }
  }

  @override
  void dispose() {
    _otpController
      ..removeListener(_syncCodeDraft)
      ..dispose();
    _lockout
      ..removeListener(_onLockoutChanged)
      ..dispose();
    _codeDraft.dispose();
    _otpFocus.dispose();
    _submitFocus.dispose();
    _resendFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layoutClass = ref.watch(appLayoutClassProvider);
    final form = _buildForm(context);
    final (title, body) = _copy(context);
    return BusyOverlay(
      isBusy: _submitting,
      label: context.t.auth.otp.submitting,
      child: AuthPageScaffold(
        screenId: 'otp',
        layoutClass: layoutClass,
        icon: FLucideIcons.badgeCheck,
        title: title,
        body: body,
        form: form,
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final translations = context.t;
    final (title, body) = _copy(context);
    final screenDirection = Directionality.of(context);
    final forcedError = switch (widget.presentation.status) {
      OtpPresentationStatus.invalid => translations.auth.otp.invalid,
      OtpPresentationStatus.expired => translations.auth.otp.expired,
      _ => null,
    };

    final alerts = <Widget>[
      ?_countdownAlert(context),
      ?_attemptsRemainingAlert(context),
      ?_feedbackAlert(context),
    ];

    return AutofillGroup(
      onDisposeAction: AutofillContextAction.cancel,
      child: Form(
        key: _formKey,
        child: Column(
          key: const ValueKey('auth-otp-form'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthFormHeader(title: title, body: body, alerts: alerts),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: AppTvEditableField(
                  activationKey: const ValueKey(
                    'auth-otp-code-activation',
                  ),
                  label: translations.auth.otp.code,
                  controller: _otpController,
                  focusNode: _otpFocus,
                  enabled: !(_submitting || _locked),
                  secure: true,
                  autofocus: true,
                  builder: (context, editorFocusNode, completeEditing) {
                    return FOtpField(
                      key: const ValueKey('auth-otp-code'),
                      formFieldKey: _otpFieldKey,
                      control: .managed(controller: _otpController),
                      focusNode: editorFocusNode,
                      label: Directionality(
                        textDirection: screenDirection,
                        child: SizedBox(
                          width: double.infinity,
                          child: Text(
                            translations.auth.otp.code,
                            textAlign: TextAlign.start,
                          ),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      textDirection: TextDirection.ltr,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp('[0-9]')),
                        LengthLimitingTextInputFormatter(6),
                      ],
                      enabled: !(_submitting || _locked),
                      autovalidateMode: AutovalidateMode.onUserInteractionIfError,
                      forceErrorText: forcedError,
                      validator: (value) {
                        if (value == null || !RegExp(r'^[0-9]{6}$').hasMatch(value)) {
                          return translations.validation.otpDigits;
                        }
                        return null;
                      },
                      errorBuilder: (context, message) => Directionality(
                        textDirection: screenDirection,
                        child: Text(message),
                      ),
                      onSaved: (value) => _savedCode = value ?? '',
                      onSubmit: (_) {
                        completeEditing();
                        unawaited(_submit());
                      },
                      onReset: () {
                        _savedCode = '';
                        _otpController.clear();
                        _otpFocus.unfocus();
                      },
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FormSubmitButton(
              buttonKey: const ValueKey('auth-otp-submit'),
              focusNode: _submitFocus,
              onPress: () => unawaited(_submit()),
              label: translations.auth.otp.submit,
              busy: _submitting,
              locked: _locked,
              retainFocusOnBusy: true,
            ),
            const SizedBox(height: AppSpacing.md),
            FormSubmitButton(
              buttonKey: const ValueKey('auth-otp-resend'),
              focusNode: _resendFocus,
              onPress: () => unawaited(_resend()),
              label: _resendLabel(context),
              busy: _resending,
              locked: _locked || widget.presentation.resendSeconds > 0,
              retainFocusOnBusy: true,
              variant: FButtonVariant.ghost,
            ),
          ],
        ),
      ),
    );
  }

  Widget? _countdownAlert(BuildContext context) {
    final remaining = widget.presentation.remainingSeconds;
    if (remaining <= 0) {
      return null;
    }
    final status = widget.presentation.status;
    if (status == OtpPresentationStatus.expired ||
        status == OtpPresentationStatus.success ||
        status == OtpPresentationStatus.globalFailure ||
        status == OtpPresentationStatus.locked) {
      return null;
    }
    return Directionality(
      textDirection: TextDirection.ltr,
      child: FAlert(
        key: const ValueKey('auth-otp-countdown'),
        icon: const Icon(FLucideIcons.clock),
        title: Text(
          context.t.auth.otp.expiresIn(n: remaining, seconds: remaining),
          textAlign: TextAlign.start,
        ),
      ),
    );
  }

  Widget? _feedbackAlert(BuildContext context) {
    final translations = context.t;
    return AuthFeedbackAlert.forStatus<OtpPresentationStatus>(
      status: widget.presentation.status,
      specFor: (status) => switch (status) {
        OtpPresentationStatus.empty ||
        OtpPresentationStatus.partial ||
        OtpPresentationStatus.pastedComplete ||
        OtpPresentationStatus.resending ||
        OtpPresentationStatus.submitting => null,
        OtpPresentationStatus.invalid => AuthFeedbackAlertSpec(
          key: const ValueKey('auth-otp-invalid'),
          variant: .destructive,
          title: Text(translations.auth.otp.invalid),
        ),
        OtpPresentationStatus.expired => AuthFeedbackAlertSpec(
          key: const ValueKey('auth-otp-expired'),
          variant: .destructive,
          title: Text(translations.auth.otp.expired),
        ),
        OtpPresentationStatus.globalFailure => AuthFeedbackAlertSpec(
          key: const ValueKey('auth-otp-global-failure'),
          variant: .destructive,
          title: Text(translations.common.notConnected),
        ),
        OtpPresentationStatus.success => AuthFeedbackAlertSpec(
          key: const ValueKey('auth-otp-success'),
          title: Text(
            switch (widget.purpose) {
              OtpPurpose.registration => translations.auth.otp.registrationSuccess,
              OtpPurpose.passwordReset => translations.auth.otp.passwordResetSuccess,
              OtpPurpose.mfa => translations.auth.otp.mfaSuccess,
            },
          ),
          icon: const Icon(FLucideIcons.circleCheck),
        ),
        OtpPresentationStatus.locked => AuthFeedbackAlertSpec(
          key: const ValueKey('auth-otp-locked'),
          variant: .destructive,
          title: Text(translations.auth.otp.lockedTitle),
          subtitle: Text(
            translations.auth.otp.lockedBody(
              n: _lockout.remainingSeconds,
              seconds: _lockout.remainingSeconds,
            ),
          ),
        ),
      },
    );
  }

  Widget? _attemptsRemainingAlert(BuildContext context) {
    return AuthAttemptsRemainingAlert.maybe(
      remaining: widget.presentation.attemptsRemaining,
      locked: widget.presentation.status == OtpPresentationStatus.locked,
      titleFor: (remaining) => Text(
        context.t.auth.otp.attemptsRemaining(n: remaining, count: remaining),
      ),
      alertKey: const ValueKey('auth-otp-attempts-remaining'),
    );
  }

  (String, String) _copy(BuildContext context) {
    final translations = context.t.auth.otp;
    return switch (widget.purpose) {
      OtpPurpose.registration => (translations.registrationTitle, translations.registrationBody),
      OtpPurpose.passwordReset => (
        translations.passwordResetTitle,
        translations.passwordResetBody,
      ),
      OtpPurpose.mfa => (translations.mfaTitle, translations.mfaBody),
    };
  }

  String _resendLabel(BuildContext context) {
    final translations = context.t.auth.otp;
    if (_resending) return translations.resending;
    if (widget.presentation.resendSeconds > 0) {
      return translations.resendIn(seconds: widget.presentation.resendSeconds);
    }
    return translations.resend;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    await submit<OtpFormValue>(
      formKey: _formKey,
      orderedTargets: [
        (
          field: _otpFieldKey.currentState,
          context: _otpFieldKey.currentContext,
          focusNode: _otpFocus,
        ),
      ],
      buildValue: () => OtpFormValue(code: _savedCode),
      onSubmit: (value) async {
        await widget.onSubmit(value);
      },
      tenFootFocusNode: _submitFocus,
    );
  }

  Future<void> _resend() async {
    if (_resendBlocked) return;
    if (context.isTenFoot) {
      _resendFocus.requestFocus();
    }
    setState(() => _callbackResending = true);
    try {
      await widget.onResend();
    } finally {
      if (mounted) setState(() => _callbackResending = false);
    }
  }
}

String _fixtureCode(OtpPresentationStatus status) {
  return switch (status) {
    OtpPresentationStatus.partial => '12',
    OtpPresentationStatus.pastedComplete => '123456',
    OtpPresentationStatus.invalid => '000000',
    OtpPresentationStatus.expired => '111111',
    _ => '',
  };
}
