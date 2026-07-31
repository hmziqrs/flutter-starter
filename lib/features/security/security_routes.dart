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
    builder: (context, state) => BiometricLockPage(
      onUnlocked: () => context.goNamed(AppRoutes.home),
      onUseFallback: () => _useBiometricFallback(context),
    ),
  ),
  GoRoute(
    name: AppRoutes.passcodeEntry,
    path: AppRoutes.passcodeEntryPath,
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

void _disableBiometricAndGoHome(BuildContext context) {
  final container = ProviderScope.containerOf(context, listen: false);
  unawaited(
    container.read(settingsControllerProvider.notifier).setBiometricUnlockEnabled(enabled: false),
  );
  context.goNamed(AppRoutes.home);
}

void _disablePasscodeAndGoHome(BuildContext context) {
  final container = ProviderScope.containerOf(context, listen: false);
  unawaited(container.read(passcodeControllerProvider.notifier).disable());
  unawaited(
    container.read(settingsControllerProvider.notifier).setPasscodeEnabled(enabled: false),
  );
  context.goNamed(AppRoutes.home);
}

void _finishPasscodeSetup(BuildContext context) {
  context.goNamed(AppRoutes.settings);
}

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
