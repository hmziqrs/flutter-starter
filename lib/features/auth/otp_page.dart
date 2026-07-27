import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:starter/app/routing/otp_purpose.dart';
import 'package:starter/features/auth/auth_form_support.dart';
import 'package:starter/features/auth/auth_page_scaffold.dart';
import 'package:starter/features/auth/otp_form_value.dart';
import 'package:starter/features/auth/otp_presentation_state.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/adaptive/app_layout_provider.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/busy_overlay.dart';

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

class _OtpViewState extends ConsumerState<_OtpView> {
  final _formKey = GlobalKey<FormState>();
  final _otpFieldKey = GlobalKey<FormFieldState<String>>();
  final _otpFocus = FocusNode(debugLabel: 'otp.code');
  late final FOtpController _otpController = FOtpController(
    value: TextEditingValue(
      text: _fixtureCode(widget.presentation.status),
      selection: TextSelection.collapsed(
        offset: _fixtureCode(widget.presentation.status).length,
      ),
    ),
  );
  bool _callbackResending = false;
  bool _callbackSubmitting = false;
  String _savedCode = '';

  // Rate-limit countdown (auth-ratelimit). Drives the live lockout seconds
  // decremented by a 1s Timer.periodic; submit and resend are OR-ed with _locked.
  Timer? _countdownTimer;
  int _liveLockedSeconds = 0;

  bool get _submitting =>
      _callbackSubmitting || widget.presentation.status == OtpPresentationStatus.submitting;

  bool get _resending =>
      _callbackResending || widget.presentation.status == OtpPresentationStatus.resending;

  bool get _locked =>
      widget.presentation.status == OtpPresentationStatus.locked && _liveLockedSeconds > 0;

  bool get _resendBlocked => _resending || widget.presentation.resendSeconds > 0 || _locked;

  @override
  void initState() {
    super.initState();
    _liveLockedSeconds = widget.presentation.lockedSeconds;
    _startLockoutCountdownIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _OtpView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.presentation.lockedSeconds != widget.presentation.lockedSeconds) {
      _liveLockedSeconds = widget.presentation.lockedSeconds;
      _startLockoutCountdownIfNeeded();
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
    _otpController.dispose();
    _otpFocus.dispose();
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

    return AutofillGroup(
      onDisposeAction: AutofillContextAction.cancel,
      child: Form(
        key: _formKey,
        child: Column(
          key: const ValueKey('auth-otp-form'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: context.theme.typography.display.xl2),
            const SizedBox(height: AppSpacing.md),
            Text(body, style: context.theme.typography.body.md),
            if (_attemptsRemainingAlert(context) case final alert?) ...[
              const SizedBox(height: AppSpacing.xl),
              alert,
            ],
            if (_feedbackAlert(context) case final alert?) ...[
              const SizedBox(height: AppSpacing.xl),
              alert,
            ],
            const SizedBox(height: AppSpacing.xl),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: FOtpField(
                  key: const ValueKey('auth-otp-code'),
                  formFieldKey: _otpFieldKey,
                  control: .managed(controller: _otpController),
                  focusNode: _otpFocus,
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
                  onSubmit: (_) => unawaited(_submit()),
                  onReset: () {
                    _savedCode = '';
                    _otpController.clear();
                    _otpFocus.unfocus();
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FButton(
              key: const ValueKey('auth-otp-submit'),
              onPress: (_submitting || _locked) ? null : () => unawaited(_submit()),
              builder: (_, _, _, _, _, child) => Flexible(child: child!),
              child: Text(
                translations.auth.otp.submit,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FButton(
              key: const ValueKey('auth-otp-resend'),
              variant: .ghost,
              onPress: _resendBlocked ? null : () => unawaited(_resend()),
              builder: (_, _, _, _, _, child) => Flexible(child: child!),
              child: Text(
                _resendLabel(context),
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
      OtpPresentationStatus.empty ||
      OtpPresentationStatus.partial ||
      OtpPresentationStatus.pastedComplete ||
      OtpPresentationStatus.resending ||
      OtpPresentationStatus.submitting => null,
      OtpPresentationStatus.invalid => FAlert(
        key: const ValueKey('auth-otp-invalid'),
        variant: .destructive,
        title: Text(translations.auth.otp.invalid),
      ),
      OtpPresentationStatus.expired => FAlert(
        key: const ValueKey('auth-otp-expired'),
        variant: .destructive,
        title: Text(translations.auth.otp.expired),
      ),
      OtpPresentationStatus.globalFailure => FAlert(
        key: const ValueKey('auth-otp-global-failure'),
        variant: .destructive,
        title: Text(translations.common.notConnected),
      ),
      OtpPresentationStatus.success => FAlert(
        key: const ValueKey('auth-otp-success'),
        title: Text(
          switch (widget.purpose) {
            OtpPurpose.registration => translations.auth.otp.registrationSuccess,
            OtpPurpose.passwordReset => translations.auth.otp.passwordResetSuccess,
          },
        ),
        icon: const Icon(FLucideIcons.circleCheck),
      ),
      OtpPresentationStatus.locked => FAlert(
        key: const ValueKey('auth-otp-locked'),
        variant: .destructive,
        title: Text(translations.auth.otp.lockedTitle),
        subtitle: Text(
          translations.auth.otp.lockedBody(n: _liveLockedSeconds, seconds: _liveLockedSeconds),
        ),
      ),
    };
  }

  /// Non-destructive "attempts remaining" notice, shown while the user still
  /// has free attempts before the next lockout. Suppressed once locked (the
  /// destructive [_feedbackAlert] carries the countdown instead).
  Widget? _attemptsRemainingAlert(BuildContext context) {
    final remaining = widget.presentation.attemptsRemaining;
    if (remaining <= 0 || widget.presentation.status == OtpPresentationStatus.locked) {
      return null;
    }
    return FAlert(
      key: const ValueKey('auth-otp-attempts-remaining'),
      title: Text(context.t.auth.otp.attemptsRemaining(n: remaining, count: remaining)),
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
    final form = _formKey.currentState;
    if (form == null) return;
    final invalidFields = form.validateGranularly();
    if (invalidFields.isNotEmpty) {
      await revealFirstAuthInvalid(
        invalidFields,
        orderedTargets: [
          (
            field: _otpFieldKey.currentState,
            context: _otpFieldKey.currentContext,
            focusNode: _otpFocus,
          ),
        ],
        isMounted: () => mounted,
      );
      return;
    }

    form.save();
    final value = OtpFormValue(code: _savedCode);
    setState(() => _callbackSubmitting = true);
    TextInput.finishAutofillContext(shouldSave: false);
    try {
      await widget.onSubmit(value);
    } finally {
      if (mounted) setState(() => _callbackSubmitting = false);
    }
  }

  Future<void> _resend() async {
    if (_resendBlocked) return;
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
