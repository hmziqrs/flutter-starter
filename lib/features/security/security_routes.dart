import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/features/security/biometric_lock_page.dart';
import 'package:starter/features/security/passcode_controller.dart';
import 'package:starter/features/security/passcode_page.dart';
import 'package:starter/features/settings/settings_controller.dart';

List<RouteBase> buildSecurityRoutes() => [
  GoRoute(
    name: AppRoutes.biometricLock,
    path: AppRoutes.biometricLockPath,
    // Top-level full-screen gate; the redirect sends protected destinations
    // here when biometric unlock is enabled and the lock subsystem is locked.
    builder: (context, state) => BiometricLockPage(
      onUnlocked: () => context.goNamed(AppRoutes.home),
      onUseFallback: () => _useBiometricFallback(context),
    ),
  ),
  GoRoute(
    name: AppRoutes.passcodeEntry,
    path: AppRoutes.passcodeEntryPath,
    // Top-level full-screen gate; the redirect sends protected destinations
    // here when a passcode challenge is armed. No back/escape until verified.
    builder: (context, state) => PasscodePage(
      mode: PasscodePageMode.entry,
      onUnlocked: () => context.goNamed(AppRoutes.home),
      onDisable: () => _disablePasscodeAndGoHome(context),
    ),
  ),
  GoRoute(
    name: AppRoutes.passcodeSetup,
    path: AppRoutes.passcodeSetupPath,
    builder: (context, state) => PasscodePage(
      mode: PasscodePageMode.setup,
      onUnlocked: () => context.goNamed(AppRoutes.home),
      onSetupComplete: () => _finishPasscodeSetup(context),
    ),
  ),
];

/// Disables biometric unlock and navigates to home. The optimistic write
/// resolves before the first await, so the redirect's live read sees
/// `biometricUnlockEnabled` flip to false on the same tick and stops gating.
void _disableBiometricAndGoHome(BuildContext context) {
  final container = ProviderScope.containerOf(context, listen: false);
  unawaited(
    container.read(settingsControllerProvider.notifier).setBiometricUnlockEnabled(enabled: false),
  );
  context.goNamed(AppRoutes.home);
}

/// Disables the passcode and its settings toggle, then navigates to home.
/// Mirrors [_disableBiometricAndGoHome].
void _disablePasscodeAndGoHome(BuildContext context) {
  final container = ProviderScope.containerOf(context, listen: false);
  unawaited(container.read(passcodeControllerProvider.notifier).disable());
  unawaited(
    container.read(settingsControllerProvider.notifier).setPasscodeEnabled(enabled: false),
  );
  context.goNamed(AppRoutes.home);
}

/// Returns to settings after the setup surface accepts a confirmed passcode.
void _finishPasscodeSetup(BuildContext context) {
  context.goNamed(AppRoutes.settings);
}

/// Biometric 'unavailable -> passcode' handoff: when a passcode is configured,
/// go there instead of disabling biometric and going home.
void _useBiometricFallback(BuildContext context) {
  final container = ProviderScope.containerOf(context, listen: false);
  try {
    final passcodeConfigured = container.read(settingsControllerProvider).passcodeEnabled;
    if (passcodeConfigured) {
      context.goNamed(AppRoutes.passcodeEntry);
      return;
    }
  } on Object {
    // No-scope test harness — fall through to the legacy disable path.
  }
  _disableBiometricAndGoHome(context);
}
