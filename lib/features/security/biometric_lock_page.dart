import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:starter/features/auth/auth_page_scaffold.dart';
import 'package:starter/features/security/biometric_unlock_controller.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/biometric/biometric_authenticator.dart';
import 'package:starter/shared/adaptive/app_layout_provider.dart';
import 'package:starter/shared/motion/app_motion.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/escape_dismissible_overlay.dart';

class BiometricLockPage extends ConsumerWidget {
  const BiometricLockPage({
    required this.onUnlocked,
    required this.onUseFallback,
    super.key,
  });

  final VoidCallback onUnlocked;

  final VoidCallback onUseFallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppLayoutScope(
      builder: (context, _) => _BiometricLockView(
        onUnlocked: onUnlocked,
        onUseFallback: onUseFallback,
      ),
    );
  }
}

class _BiometricLockView extends ConsumerStatefulWidget {
  const _BiometricLockView({required this.onUnlocked, required this.onUseFallback});

  final VoidCallback onUnlocked;
  final VoidCallback onUseFallback;

  @override
  ConsumerState<_BiometricLockView> createState() => _BiometricLockViewState();
}

class _BiometricLockViewState extends ConsumerState<_BiometricLockView> {
  bool _unlocking = false;
  bool _lastAttemptFailed = false;

  @override
  Widget build(BuildContext context) {
    final layoutClass = ref.watch(appLayoutClassProvider);
    final state = ref.watch(biometricUnlockControllerProvider);
    final translations = context.t.security.biometric;
    final isUnavailable = state is BiometricLockUnavailable;

    final title = isUnavailable ? translations.unavailableTitle : translations.lockTitle;
    final body = isUnavailable ? translations.unavailableBody : translations.lockBody;

    return EscapeDismissibleOverlay(
      child: AuthPageScaffold(
        screenId: 'biometric-lock',
        layoutClass: layoutClass,
        icon: isUnavailable ? FLucideIcons.lockKeyhole : FLucideIcons.scanFace,
        title: title,
        body: body,
        form: _buildForm(context, isUnavailable: isUnavailable),
      ),
    );
  }

  Widget _buildForm(BuildContext context, {required bool isUnavailable}) {
    final translations = context.t.security.biometric;
    return Column(
      key: const ValueKey('biometric-lock-form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: _BiometricLockIcon(unavailable: isUnavailable),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          isUnavailable ? translations.unavailableTitle : translations.lockTitle,
          key: const ValueKey('biometric-lock-title'),
          style: context.theme.typography.display.xl2,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          isUnavailable ? translations.unavailableBody : translations.lockBody,
          key: const ValueKey('biometric-lock-body'),
          style: context.theme.typography.body.md,
          textAlign: TextAlign.center,
        ),
        if (_lastAttemptFailed) ...[
          const SizedBox(height: AppSpacing.xl),
          FAlert(
            key: const ValueKey('biometric-lock-failure'),
            variant: .destructive,
            title: Text(translations.authFailedTitle),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        if (isUnavailable)
          FButton(
            key: const ValueKey('biometric-lock-fallback'),
            onPress: widget.onUseFallback,
            child: Text(translations.useFallback),
          )
        else
          FButton(
            key: const ValueKey('biometric-lock-unlock'),
            onPress: _unlocking ? null : () => unawaited(_unlock()),
            child: Text(_unlocking ? translations.unlocking : translations.unlock),
          ),
      ],
    );
  }

  Future<void> _unlock() async {
    if (_unlocking) return;
    final controller = ref.read(biometricUnlockControllerProvider.notifier);
    final reason = context.t.security.biometric.lockBody;
    setState(() {
      _unlocking = true;
      _lastAttemptFailed = false;
    });
    try {
      final ok = await controller.authenticate(localizedReason: reason);
      if (!mounted) return;
      if (ok) {
        widget.onUnlocked();
      } else {
        setState(() => _lastAttemptFailed = true);
      }
    } finally {
      if (mounted) {
        setState(() => _unlocking = false);
      }
    }
  }
}

final _motionScale = MovieTweenProperty<double>();
final _motionOpacity = MovieTweenProperty<double>();

class _BiometricLockIcon extends StatelessWidget {
  const _BiometricLockIcon({required this.unavailable});

  final bool unavailable;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      unavailable ? FLucideIcons.lockKeyhole : FLucideIcons.scanFace,
      size: context.spacing.xl3,
      color: context.theme.colors.primary,
    );
    if (MediaQuery.disableAnimationsOf(context)) {
      return icon;
    }

    final tween = MovieTween()
      ..tween<double>(
        _motionScale,
        Tween(begin: 0.85, end: 1),
        duration: AppMotion.standard,
        curve: AppMotion.emphasizedCurve,
      )
      ..tween<double>(
        _motionOpacity,
        Tween(begin: 0, end: 1),
        duration: AppMotion.standard,
        curve: AppMotion.standardCurve,
      );

    return PlayAnimationBuilder<Movie>(
      tween: tween,
      duration: tween.duration,
      child: KeyedSubtree(key: ValueKey(unavailable), child: icon),
      builder: (context, movie, child) {
        return Opacity(
          opacity: _motionOpacity.from(movie),
          child: Transform.scale(scale: _motionScale.from(movie), child: child),
        );
      },
    );
  }
}
