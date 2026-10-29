import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/auth/auth_page_scaffold.dart';
import 'package:starter/features/auth/widgets/auth_feedback_alert.dart';
import 'package:starter/features/security/auto_lock_controller.dart';
import 'package:starter/features/security/passcode_controller.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/adaptive/app_layout_provider.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/theme/brand_tokens.dart';
import 'package:starter/shared/widgets/brand/app_ring_marker.dart';
import 'package:starter/shared/widgets/escape_dismissible_overlay.dart';

enum PasscodePageMode { entry, setup }

class PasscodePage extends ConsumerWidget {
  const PasscodePage({
    required this.mode,
    required this.onUnlocked,
    this.onSetupComplete,
    this.onDisable,
    this.passcodeLength = defaultPasscodeLength,
    super.key,
  });

  final int passcodeLength;

  static const defaultPasscodeLength = 4;

  final VoidCallback onUnlocked;

  final VoidCallback? onSetupComplete;

  final VoidCallback? onDisable;

  final PasscodePageMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppLayoutScope(
      builder: (context, _) => _PasscodeView(
        mode: mode,
        passcodeLength: passcodeLength,
        onUnlocked: onUnlocked,
        onSetupComplete: onSetupComplete,
        onDisable: onDisable,
      ),
    );
  }
}

class _PasscodeView extends ConsumerStatefulWidget {
  const _PasscodeView({
    required this.mode,
    required this.passcodeLength,
    required this.onUnlocked,
    required this.onSetupComplete,
    required this.onDisable,
  });

  final PasscodePageMode mode;
  final int passcodeLength;
  final VoidCallback onUnlocked;
  final VoidCallback? onSetupComplete;
  final VoidCallback? onDisable;

  @override
  ConsumerState<_PasscodeView> createState() => _PasscodeViewState();
}

class _PasscodeViewState extends ConsumerState<_PasscodeView> {
  final TextEditingController _entryController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final FocusNode _entryFocus = FocusNode();
  final FocusNode _confirmFocus = FocusNode();
  bool _submitting = false;
  String? _entryError;
  String? _setupError;

  @override
  void dispose() {
    _entryController.dispose();
    _confirmController.dispose();
    _entryFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final translations = context.t.security.passcode;
    final passcodeState = ref.watch(passcodeControllerProvider);
    final layoutClass = ref.watch(appLayoutClassProvider);

    final (title, body, icon) = switch (widget.mode) {
      PasscodePageMode.entry => (
        translations.enterTitle,
        translations.enterBody,
        FLucideIcons.lockKeyhole,
      ),
      PasscodePageMode.setup => (
        _confirmFocus.hasFocus ? translations.confirmTitle : translations.setupTitle,
        translations.setupBody,
        FLucideIcons.lock,
      ),
    };

    return EscapeDismissibleOverlay(
      child: AuthPageScaffold(
        screenId: widget.mode == PasscodePageMode.entry ? 'passcode-entry' : 'passcode-setup',
        layoutClass: layoutClass,
        icon: icon,
        title: title,
        body: body,
        form: _buildForm(context, passcodeState: passcodeState),
      ),
    );
  }

  Widget _buildForm(BuildContext context, {required PasscodeState passcodeState}) {
    return Material(
      type: MaterialType.transparency,
      child: Column(
        key: const ValueKey('passcode-form'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.mode == PasscodePageMode.entry)
            _buildEntrySurface(context, passcodeState: passcodeState)
          else
            _buildSetupSurface(context),
          if (_entryError != null || _setupError != null) ...[
            SizedBox(height: context.spacing.lg),
            AuthFeedbackAlert<Object>(
              spec: AuthFeedbackAlertSpec(
                key: ValueKey('passcode-error-${_entryError ?? _setupError}'),
                role: AppStatusRole.destructive,
                title: Text(_entryError ?? _setupError!),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEntrySurface(BuildContext context, {required PasscodeState passcodeState}) {
    final translations = context.t.security.passcode;
    final spacing = context.spacing;
    final now = DateTime.now();
    final lockedSeconds = passcodeState.lockedSecondsAt(now);
    final isLockedOut = passcodeState.isLockedAt(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          translations.enterTitle,
          key: const ValueKey('passcode-entry-title'),
          style: entryPageTitleStyle(context),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: spacing.md),
        Text(
          translations.enterBody,
          key: const ValueKey('passcode-entry-body'),
          style: entryMutedBodyStyle(context),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: spacing.xl),
        _PasscodeDots(
          filled: _entryController.text.length,
          total: widget.passcodeLength,
          alert: isLockedOut,
        ),
        SizedBox(height: spacing.lg),
        if (isLockedOut)
          _LockedOutNotice(seconds: lockedSeconds)
        else
          _digitField(
            context,
            key: const ValueKey('passcode-entry-field'),
            controller: _entryController,
            focusNode: _entryFocus,
            labelText: translations.enterTitle,
            autofillHints: const [AutofillHints.password],
            onChanged: (_) {
              if (mounted) setState(() {});
              if (_entryController.text.length == widget.passcodeLength) {
                unawaited(_submitEntry());
              }
            },
            onSubmitted: (_) => unawaited(_submitEntry()),
            autofocus: true,
          ),
        SizedBox(height: spacing.lg),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FButton(
              key: const ValueKey('passcode-unlock'),
              onPress: _submitting || isLockedOut ? null : () => unawaited(_submitEntry()),
              child: Text(translations.enterTitle),
            ),
            if (widget.onDisable != null) ...[
              SizedBox(height: spacing.md),
              FButton(
                key: const ValueKey('passcode-disable'),
                variant: .ghost,
                onPress: _submitting ? null : widget.onDisable,
                child: Text(translations.disable),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildSetupSurface(BuildContext context) {
    final translations = context.t.security.passcode;
    final spacing = context.spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PasscodeDots(
          filled: (_confirmFocus.hasFocus ? _confirmController : _entryController).text.length,
          total: widget.passcodeLength,
          alert: false,
        ),
        SizedBox(height: spacing.lg),
        Form(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _digitField(
                context,
                key: const ValueKey('passcode-setup-entry'),
                controller: _entryController,
                focusNode: _entryFocus,
                labelText: translations.setupTitle,
                onChanged: (_) {
                  if (mounted) setState(() {});
                  if (_entryController.text.length == widget.passcodeLength) {
                    _confirmFocus.requestFocus();
                  }
                },
                autofocus: true,
              ),
              SizedBox(height: spacing.md),
              _digitField(
                context,
                key: const ValueKey('passcode-setup-confirm'),
                controller: _confirmController,
                focusNode: _confirmFocus,
                labelText: translations.reenter,
                onChanged: (_) {
                  if (mounted) setState(() {});
                },
                onSubmitted: (_) => unawaited(_submitSetup()),
              ),
            ],
          ),
        ),
        SizedBox(height: spacing.lg),
        FButton(
          key: const ValueKey('passcode-setup-submit'),
          onPress: _submitting ? null : () => unawaited(_submitSetup()),
          child: Text(translations.confirmTitle),
        ),
      ],
    );
  }

  Widget _digitField(
    BuildContext context, {
    required Key key,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String labelText,
    required ValueChanged<String> onChanged,
    ValueChanged<String>? onSubmitted,
    List<String>? autofillHints,
    bool autofocus = false,
  }) {
    return TextField(
      key: key,
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.number,
      keyboardAppearance: Theme.of(context).brightness,
      maxLength: widget.passcodeLength,
      obscureText: true,
      enableInteractiveSelection: false,
      autofillHints: autofillHints,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(counterText: '', labelText: labelText),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      autofocus: autofocus,
    );
  }

  Future<void> _submitEntry() async {
    if (_submitting) return;
    final value = _entryController.text;
    if (value.length != widget.passcodeLength) return;
    final translations = context.t.security.passcode;
    setState(() {
      _submitting = true;
      _entryError = null;
    });
    try {
      final result = await ref.read(passcodeControllerProvider.notifier).verify(value);
      if (!mounted) return;
      switch (result) {
        case PasscodeVerifyResult.success:
          ref.read(autoLockControllerProvider.notifier).unlock();
          widget.onUnlocked();
        case PasscodeVerifyResult.incorrect:
          final remaining = ref.read(passcodeControllerProvider).attemptsRemaining;
          _signalIncorrect(
            message: translations.incorrect(n: remaining, attempts: remaining),
          );
        case PasscodeVerifyResult.lockedOut:
          final secs = ref.read(passcodeControllerProvider).lockedSecondsAt(DateTime.now());
          setState(() {
            _entryError = translations.lockedOut(n: secs, seconds: secs);
          });
        case PasscodeVerifyResult.notConfigured:
          widget.onUnlocked();
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _submitSetup() async {
    if (_submitting) return;
    final translations = context.t.security.passcode;
    final entry = _entryController.text;
    final confirm = _confirmController.text;
    if (entry.length != widget.passcodeLength || confirm.length != widget.passcodeLength) {
      return;
    }
    setState(() {
      _submitting = true;
      _setupError = null;
    });
    try {
      if (entry != confirm) {
        setState(() {
          _setupError = translations.mismatch;
          _confirmController.clear();
        });
        _confirmFocus.requestFocus();
        return;
      }
      await ref.read(passcodeControllerProvider.notifier).setPasscode(entry);
      if (!mounted) return;
      ref.read(autoLockControllerProvider.notifier).unlock();
      widget.onSetupComplete?.call();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// Wrong-passcode feedback is color and copy only: the notice below the dots
  /// carries the error and the entry clears for the next try (BRAND.md s10).
  void _signalIncorrect({required String message}) {
    _entryController.clear();
    setState(() => _entryError = message);
    _entryFocus.requestFocus();
  }
}

class _PasscodeDots extends StatelessWidget {
  const _PasscodeDots({
    required this.filled,
    required this.total,
    required this.alert,
  });

  final int filled;
  final int total;

  /// True while the entry is locked out: the markers read destructive instead
  /// of animating.
  final bool alert;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < total; i++)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.spacing.xs),
                  child: AppRingMarker(
                    filled: i < filled && !alert,
                    color: _dotColor(context, filledNow: i < filled, alert: alert),
                    size: 10,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Color _dotColor(BuildContext context, {required bool filledNow, required bool alert}) {
    final brand = context.theme.brand;
    final colors = context.theme.colors;
    if (alert) {
      return brand.destructive;
    }
    return filledNow ? colors.primary : colors.mutedForeground;
  }
}

class _LockedOutNotice extends StatelessWidget {
  const _LockedOutNotice({required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context) {
    final translations = context.t.security.passcode;
    return FAlert(
      key: const ValueKey('passcode-locked-out'),
      style: AuthFeedbackAlert.noticeStyle(context, AppStatusRole.destructive),
      icon: const Icon(FLucideIcons.octagonAlert),
      title: Text(
        translations.lockedOut(n: seconds, seconds: seconds),
        textAlign: TextAlign.center,
      ),
    );
  }
}
