import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/auth/auth_page_scaffold.dart';
import 'package:starter/features/auth/widgets/auth_feedback_alert.dart';
import 'package:starter/features/security/biometric_unlock_controller.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/biometric/biometric_authenticator.dart';
import 'package:starter/shared/adaptive/app_layout_provider.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/theme/brand_tokens.dart';
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
    final translations = context.t.security.biometric;
    final isUnavailable = ref.watch(
      biometricUnlockControllerProvider.select((s) => s is BiometricLockUnavailable),
    );

    final title = isUnavailable ? translations.unavailableTitle : translations.lockTitle;
    final body = isUnavailable ? translations.unavailableBody : translations.lockBody;

    return EscapeDismissibleOverlay(
      child: AuthPageScaffold(
        screenId: 'biometric-lock',
        layoutClass: layoutClass,
        title: title,
        body: body,
        titleKey: const ValueKey('biometric-lock-title'),
        bodyKey: const ValueKey('biometric-lock-body'),
        form: _buildForm(context, isUnavailable: isUnavailable),
      ),
    );
  }

  Widget _buildForm(BuildContext context, {required bool isUnavailable}) {
    final translations = context.t.security.biometric;
    final spacing = context.spacing;
    return Column(
      key: const ValueKey('biometric-lock-form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_lastAttemptFailed) ...[
          FAlert(
            key: const ValueKey('biometric-lock-failure'),
            style: AuthFeedbackAlert.noticeStyle(context, AppStatusRole.destructive),
            icon: const Icon(FLucideIcons.octagonAlert),
            title: Text(translations.authFailedTitle),
          ),
          SizedBox(height: spacing.lg),
        ],
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
