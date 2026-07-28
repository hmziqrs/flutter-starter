import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:starter/features/auth/auth_page_scaffold.dart';
import 'package:starter/features/security/auto_lock_controller.dart';
import 'package:starter/features/security/passcode_controller.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/adaptive/app_layout_provider.dart';
import 'package:starter/shared/motion/app_motion.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/escape_dismissible_overlay.dart';

/// The two surfaces this page renders. The entry surface is the full-screen
/// gate the C5 redirect sends a protected destination to; the setup surface is
/// pushed from settings when the user turns passcode protection on.
enum PasscodePageMode { entry, setup }

/// Full-screen passcode gate (entry) and configuration surface (setup).
///
/// Rendered by the top-level `passcodeEntry` / `passcodeSetup` routes (outside
/// the shell, like the auth routes and the biometric lock). It consumes the
/// shared [AuthPageScaffold] (the adaptive auth shell) and
/// [EscapeDismissibleOverlay] (keyboard focus + Escape handling).
///
/// The page performs no plugin calls and never calls `go_router` directly.
/// Every side effect goes through a callback ([onUnlocked] / [onSetupComplete]
/// navigation, [onDisable] escape) or the [PasscodeController] /
/// [AutoLockController] ports. Navigation fires immediately on a successful
/// unlock and never gates on the shake / countdown animations (motion rule 5):
/// the non-animated fallback still clears the field and updates the attempt
/// counter when the platform requests reduced motion.
///
/// The entry surface is a **hard gate**: it has no back/escape navigation
/// until the passcode verifies (or the user disables). The redirect is the
/// enforcer, not a per-route trap — Escape dismissal is harmless because the
/// redirect re-sends any protected destination straight back to the entry path
/// while [PasscodeState.requiresChallenge] holds.
class PasscodePage extends ConsumerWidget {
  const PasscodePage({
    required this.mode,
    required this.onUnlocked,
    this.onSetupComplete,
    this.onDisable,
    this.passcodeLength = defaultPasscodeLength,
    super.key,
  });

  /// The configured digit length. Defaults to 4 (banking/enterprise default);
  /// the setup surface validates the same length for both entries.
  final int passcodeLength;

  static const defaultPasscodeLength = 4;

  /// Invoked the moment an entry-surface verify succeeds. The composition root
  /// wires this to `context.goNamed(home)` after clearing the auto-lock state.
  /// Also used by the setup surface's success path.
  final VoidCallback onUnlocked;

  /// Invoked when the setup surface accepts a confirmed passcode. The
  /// composition root navigates back to settings (or home). Distinct from
  /// [onUnlocked] so the two flows can route differently.
  final VoidCallback? onSetupComplete;

  /// Escape hatch for the entry surface: disables the passcode and clears the
  /// gate. Optional — when null the disable affordance is hidden (the user
  /// cannot disable from the entry screen without it).
  final VoidCallback? onDisable;

  final PasscodePageMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // AppLayoutScope is provided here so the descendant _PasscodeView can read
    // `appLayoutClassProvider` (which resolves through the inherited scope).
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
  bool _shake = false;
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
    // The raw Material TextFields below need a Material ancestor; the shared
    // AuthPageScaffold uses ForUI's FScaffold (no implicit Material). A
    // transparent Material provides the ancestor without altering the surface.
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
            const SizedBox(height: AppSpacing.lg),
            FAlert(
              key: ValueKey('passcode-error-${_entryError ?? _setupError}'),
              variant: .destructive,
              title: Text(_entryError ?? _setupError!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEntrySurface(BuildContext context, {required PasscodeState passcodeState}) {
    final translations = context.t.security.passcode;
    final now = DateTime.now();
    final lockedSeconds = passcodeState.lockedSecondsAt(now);
    final isLockedOut = passcodeState.isLockedAt(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          translations.enterTitle,
          key: const ValueKey('passcode-entry-title'),
          style: context.theme.typography.display.xl2,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          translations.enterBody,
          key: const ValueKey('passcode-entry-body'),
          style: context.theme.typography.body.md,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        _PasscodeDots(
          filled: _entryController.text.length,
          total: widget.passcodeLength,
          pulse: isLockedOut,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (isLockedOut)
          _LockedOutNotice(seconds: lockedSeconds)
        else
          TextField(
            key: const ValueKey('passcode-entry-field'),
            controller: _entryController,
            focusNode: _entryFocus,
            keyboardType: TextInputType.number,
            keyboardAppearance: Theme.of(context).brightness,
            maxLength: widget.passcodeLength,
            obscureText: true,
            enableInteractiveSelection: false,
            autofillHints: const [AutofillHints.password],
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              counterText: '',
              labelText: translations.enterTitle,
            ),
            onChanged: (_) {
              if (mounted) setState(() {});
              if (_entryController.text.length == widget.passcodeLength) {
                unawaited(_submitEntry());
              }
            },
            onSubmitted: (_) => unawaited(_submitEntry()),
            autofocus: true,
          ),
        const SizedBox(height: AppSpacing.lg),
        // Shake wrapper is applied around the actions so an incorrect attempt
        // nudges the whole surface; the non-animated fallback (reduce-motion)
        // still clears the field and updates the attempt counter.
        _ShakeGuard(
          shaking: _shake,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FButton(
                key: const ValueKey('passcode-unlock'),
                onPress: _submitting || isLockedOut ? null : () => unawaited(_submitEntry()),
                child: Text(translations.enterTitle),
              ),
              if (widget.onDisable != null) ...[
                const SizedBox(height: AppSpacing.md),
                FButton(
                  key: const ValueKey('passcode-disable'),
                  variant: .ghost,
                  onPress: _submitting ? null : widget.onDisable,
                  child: Text(translations.disable),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSetupSurface(BuildContext context) {
    final translations = context.t.security.passcode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PasscodeDots(
          filled: (_confirmFocus.hasFocus ? _confirmController : _entryController).text.length,
          total: widget.passcodeLength,
          pulse: false,
        ),
        const SizedBox(height: AppSpacing.lg),
        Form(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const ValueKey('passcode-setup-entry'),
                controller: _entryController,
                focusNode: _entryFocus,
                keyboardType: TextInputType.number,
                keyboardAppearance: Theme.of(context).brightness,
                maxLength: widget.passcodeLength,
                obscureText: true,
                enableInteractiveSelection: false,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  counterText: '',
                  labelText: translations.setupTitle,
                ),
                onChanged: (_) {
                  if (mounted) setState(() {});
                  if (_entryController.text.length == widget.passcodeLength) {
                    _confirmFocus.requestFocus();
                  }
                },
                autofocus: true,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                key: const ValueKey('passcode-setup-confirm'),
                controller: _confirmController,
                focusNode: _confirmFocus,
                keyboardType: TextInputType.number,
                keyboardAppearance: Theme.of(context).brightness,
                maxLength: widget.passcodeLength,
                obscureText: true,
                enableInteractiveSelection: false,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  counterText: '',
                  labelText: translations.reenter,
                ),
                onChanged: (_) {
                  if (mounted) setState(() {});
                },
                onSubmitted: (_) => unawaited(_submitSetup()),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FButton(
          key: const ValueKey('passcode-setup-submit'),
          onPress: _submitting ? null : () => unawaited(_submitSetup()),
          child: Text(translations.confirmTitle),
        ),
      ],
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
          // Nothing to verify against — treat as unlocked so the user is not
          // trapped on a gate with no credential.
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
      // Setup arms nothing within this session (the user just chose the value);
      // clear auto-lock in case a prior session had armed it.
      ref.read(autoLockControllerProvider.notifier).unlock();
      widget.onSetupComplete?.call();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _signalIncorrect({required String message}) {
    _entryController.clear();
    if (mounted) setState(() {});
    // The shake is a micro-interaction; under reduce-motion it is skipped but
    // the error message + cleared field still surface the failure (motion
    // rule 5: the non-animated fallback completes the action).
    if (!MediaQuery.disableAnimationsOf(context)) {
      setState(() {
        _shake = true;
        _entryError = message;
      });
      Future<void>.delayed(AppMotion.deliberate, () {
        if (mounted) setState(() => _shake = false);
      });
    } else {
      setState(() => _entryError = message);
    }
    _entryFocus.requestFocus();
  }
}

/// Row of passcode dots. The fill is driven by the controller text length so it
/// is deterministic for tests and the dev-gallery (no timing-sensitive cursor).
/// A slow pulse on the locked-out case is the only animation, guarded by the
/// caller's reduce-motion check at the call site (the dots themselves render
/// statically when [pulse] is false).
class _PasscodeDots extends StatelessWidget {
  const _PasscodeDots({required this.filled, required this.total, required this.pulse});

  final int filled;
  final int total;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Dots are LTR-numeric per the i18n RTL note; wrap in a fixed
        // Directionality so an Arabic locale does not mirror the digit order.
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < total; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  child: _Dot(active: i < filled, pulse: pulse && i < filled),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.active, required this.pulse});

  final bool active;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    final color = active ? context.theme.colors.primary : context.theme.colors.mutedForeground;
    final icon = Icon(
      active ? FLucideIcons.circle : FLucideIcons.circleDashed,
      size: 18,
      color: color,
    );
    if (!pulse || MediaQuery.disableAnimationsOf(context)) {
      return icon;
    }
    final tween = MovieTween()
      ..tween<double>(
        _dotScale,
        Tween(begin: 1, end: 0.8),
        duration: AppMotion.deliberate,
        curve: AppMotion.standardCurve,
      );
    return LoopAnimationBuilder<Movie>(
      tween: tween,
      duration: tween.duration,
      builder: (context, movie, child) =>
          Transform.scale(scale: _dotScale.from(movie), child: child),
      child: icon,
    );
  }
}

class _LockedOutNotice extends StatelessWidget {
  const _LockedOutNotice({required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context) {
    final translations = context.t.security.passcode;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Text(
        translations.lockedOut(n: seconds, seconds: seconds),
        key: const ValueKey('passcode-locked-out'),
        style: context.theme.typography.body.lg,
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Wraps a subtree in an optional horizontal shake. When [shaking] is false or
/// the platform requests reduced motion, the child renders untouched. The shake
/// never blocks a downstream navigation: the caller invokes the navigation
/// callback directly and this wrapper only animates presentation.
class _ShakeGuard extends StatelessWidget {
  const _ShakeGuard({required this.shaking, required this.child});

  final bool shaking;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!shaking || MediaQuery.disableAnimationsOf(context)) {
      return child;
    }
    final tween = MovieTween()
      ..tween<double>(
        _shakeX,
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0, end: -8), weight: 1),
          TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 8, end: -4), weight: 2),
          TweenSequenceItem(tween: Tween(begin: -4, end: 0), weight: 1),
        ]),
        duration: AppMotion.standard,
        curve: AppMotion.standardCurve,
      );
    return PlayAnimationBuilder<Movie>(
      tween: tween,
      duration: tween.duration,
      builder: (context, movie, child) => Transform.translate(
        offset: Offset(_shakeX.from(movie), 0),
        child: child,
      ),
      child: child,
    );
  }
}

final _dotScale = MovieTweenProperty<double>();
final _shakeX = MovieTweenProperty<double>();
