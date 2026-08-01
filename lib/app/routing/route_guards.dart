import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/features/force_update/force_update_state.dart';
import 'package:starter/features/force_update/soft_update_dialog.dart';
import 'package:starter/features/force_update/update_requirement.dart';
import 'package:starter/features/force_update/version_gate_providers.dart';
import 'package:starter/features/security/biometric_unlock_controller.dart';
import 'package:starter/features/security/passcode_controller.dart';
import 'package:starter/features/session/auth_session.dart';
import 'package:starter/features/session/session_controller.dart';
import 'package:starter/features/settings/settings_controller.dart';
import 'package:starter/features/settings/settings_page.dart';
import 'package:starter/features/settings/settings_store.dart';
import 'package:starter/infrastructure/biometric/biometric_authenticator.dart';
import 'package:url_launcher/url_launcher.dart';

String? appRedirect(
  BuildContext context,
  GoRouterState state, {
  bool hasCompletedOnboardingSeed = false,
}) {
  final path = state.uri.path;

  final requirement = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(versionCheckProvider).value;
  if (requirement is UpdateRequirementHard) {
    return path == AppRoutes.forceUpdatePath ? null : AppRoutes.forceUpdatePath;
  }
  if (requirement is UpdateRequirementSoft) {
    _maybeShowSoftUpdateDialog(context, requirement);
  }

  if (path == AppRoutes.appearanceSettingsPath) {
    return state.uri
        .replace(
          path: AppRoutes.settingsPath,
          queryParameters: {'section': SettingsSection.appearance.parameter},
        )
        .toString();
  }
  if (path == AppRoutes.languageSettingsPath) {
    return state.uri
        .replace(
          path: AppRoutes.settingsPath,
          queryParameters: {'section': SettingsSection.language.parameter},
        )
        .toString();
  }

  if (_isOnboardingOrAuthRoute(path)) {
    return null;
  }
  final hasCompleted = _readLiveHasCompletedOnboarding(context) ?? hasCompletedOnboardingSeed;
  if (_isShellTabDestination(path) && !hasCompleted) {
    return AppRoutes.onboardingPath;
  }

  if (_isAuthRequiredDestination(path) && hasCompleted) {
    final session = _readLiveSession(context) ?? const AuthAnonymous();
    if (session is! AuthAuthenticated) {
      return AppRoutes.loginPath;
    }
  }

  if (!_isShellTabDestination(path)) {
    return null;
  }
  if (_readLiveBiometricUnlockActive(context)) {
    return AppRoutes.biometricLockPath;
  }
  if (!_isPasscodeRoute(path) && _readLivePasscodeRequiresChallenge(context)) {
    return AppRoutes.passcodeEntryPath;
  }
  return null;
}

bool _isShellTabDestination(String path) =>
    path == AppRoutes.homePath || path == AppRoutes.pricingPath || path == AppRoutes.settingsPath;

bool _isOnboardingOrAuthRoute(String path) =>
    path == AppRoutes.onboardingPath ||
    path.startsWith('${AppRoutes.onboardingPath}/') ||
    path.startsWith('/auth/');

bool _isAuthRequiredDestination(String path) => path == AppRoutes.updateProfilePath;

bool? _readLiveHasCompletedOnboarding(BuildContext context) {
  try {
    final container = ProviderScope.containerOf(context, listen: false);
    return container.read(settingsControllerProvider).hasCompletedOnboarding;
  } on Object {
    return null;
  }
}

AuthSession? _readLiveSession(BuildContext context) {
  try {
    final container = ProviderScope.containerOf(context, listen: false);
    return container.read(sessionControllerProvider);
  } on Object {
    return null;
  }
}

bool _readLiveBiometricUnlockActive(BuildContext context) {
  try {
    final container = ProviderScope.containerOf(context, listen: false);
    final enabled = container.read(settingsControllerProvider).biometricUnlockEnabled;
    if (!enabled) return false;
    return container.read(biometricUnlockControllerProvider) is BiometricLockLocked;
  } on Object {
    return false;
  }
}

final softUpdatePromptShownProvider = NotifierProvider<_SoftUpdatePromptShown, bool>(
  _SoftUpdatePromptShown.new,
);

class _SoftUpdatePromptShown extends Notifier<bool> {
  @override
  bool build() => false;

  void markShown() => state = true;
}

void _maybeShowSoftUpdateDialog(BuildContext context, UpdateRequirementSoft requirement) {
  final container = ProviderScope.containerOf(context, listen: false);
  if (container.read(softUpdatePromptShownProvider)) {
    return;
  }
  final store = container.read(settingsStoreProvider);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) {
      return;
    }
    unawaited(
      store.readString(SoftUpdateSnooze.key).then((stored) {
        if (!context.mounted || SoftUpdateSnooze.isSnoozed(stored)) {
          return;
        }
        if (container.read(softUpdatePromptShownProvider)) {
          return;
        }
        container.read(softUpdatePromptShownProvider.notifier).markShown();
        unawaited(
          showSoftUpdateDialog(
            context,
            state: ForceUpdateState.from(requirement),
            onUpdate: () => unawaited(launchStoreUrl(requirement.storeUrl)),
            onLater: () => store.writeString(SoftUpdateSnooze.key, SoftUpdateSnooze.encode()),
          ),
        );
      }),
    );
  });
}

Future<void> launchStoreUrl(String storeUrl) async {
  final uri = Uri.tryParse(storeUrl);
  if (uri == null) {
    return;
  }
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on Object {
    // ignored
  }
}

bool _readLivePasscodeRequiresChallenge(BuildContext context) {
  try {
    final container = ProviderScope.containerOf(context, listen: false);
    final enabled = container.read(settingsControllerProvider).passcodeEnabled;
    if (!enabled) return false;
    return container.read(passcodeControllerProvider).requiresChallenge;
  } on Object {
    return false;
  }
}

bool _isPasscodeRoute(String path) =>
    path == AppRoutes.passcodeEntryPath || path == AppRoutes.passcodeSetupPath;
