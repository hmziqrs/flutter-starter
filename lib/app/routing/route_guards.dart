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

// Single redirect: predicates chained in priority order, each returning the
// first non-null target. Precedence: update-blocker HARD -> settings
// normalization -> onboarding -> session -> biometric -> passcode. The
// onboarding gate runs before the session gate so a fresh install always sees
// onboarding first, even for an auth-required destination. SOFT never
// redirects — it triggers a post-frame dialog instead. NONE / loading / error
// fall through.
String? appRedirect(
  BuildContext context,
  GoRouterState state, {
  bool hasCompletedOnboardingSeed = false,
}) {
  final path = state.uri.path;

  // Update-blocker HARD wins over everything: any route other than
  // /force-update redirects there; on /force-update returns null (no loop).
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

  // Settings deep-link normalization.
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

  // Onboarding gate runs before the session gate. Deep links and auth flows
  // must never be hijacked into an onboarding loop, so skip when already on
  // an onboarding or auth route.
  if (_isOnboardingOrAuthRoute(path)) {
    return null;
  }
  // Live read so the in-session Skip -> markOnboardingComplete -> goNamed(home)
  // path is observable on the same tick; a captured bool would bounce home ->
  // onboarding until relaunch.
  final hasCompleted = _readLiveHasCompletedOnboarding(context) ?? hasCompletedOnboardingSeed;
  // Only shell-tab destinations gate through onboarding; detail routes
  // (/profile/edit, /dev/*) only render once the shell has cleared onboarding.
  if (_isShellTabDestination(path) && !hasCompleted) {
    return AppRoutes.onboardingPath;
  }

  // Session auth-required gate, evaluated after onboarding so onboarding wins
  // for fresh installs. An anonymous user hitting an auth-only destination is
  // sent to /auth/login.
  if (_isAuthRequiredDestination(path) && hasCompleted) {
    final session = _readLiveSession(context) ?? const AuthAnonymous();
    if (session is! AuthAuthenticated) {
      return AppRoutes.loginPath;
    }
  }

  // Non-shell-tab, non-auth-required detail routes (/dev/*) stop here — they
  // do not re-gate through biometric/passcode independently.
  if (!_isShellTabDestination(path)) {
    return null;
  }
  // Biometric gate: a returning user on a shell-tab destination whose lock
  // subsystem is BiometricLockLocked is sent to /lock. Unavailable never
  // redirects, so a device without biometric is never looped into a dead end.
  if (_readLiveBiometricUnlockActive(context)) {
    return AppRoutes.biometricLockPath;
  }
  // Passcode gate runs last: a user with both biometric and passcode enabled
  // hits biometric first, and its onUseFallback hands off to /passcode. Armed
  // by AutoLockController on idle timeout / background return; an active
  // brute-force lockout keeps requiresChallenge false but the user is already
  // on /passcode (a hard gate with no escape until verified).
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

/// Auth-only destinations: routes a user must be signed in to reach. Today only
/// profile editing is gated; extend this set as auth-required surfaces grow.
bool _isAuthRequiredDestination(String path) => path == AppRoutes.updateProfilePath;

bool? _readLiveHasCompletedOnboarding(BuildContext context) {
  try {
    final container = ProviderScope.containerOf(context, listen: false);
    return container.read(settingsControllerProvider).hasCompletedOnboarding;
  } on Object {
    // Test-harness fallback (no ProviderScope above the router); production
    // always wires the scope so the live read wins.
    return null;
  }
}

/// Reads live session state so an in-session login/logout is observable on
/// the same tick.
AuthSession? _readLiveSession(BuildContext context) {
  try {
    final container = ProviderScope.containerOf(context, listen: false);
    return container.read(sessionControllerProvider);
  } on Object {
    return null;
  }
}

/// True when biometric unlock is enabled in settings AND the lock subsystem
/// is [BiometricLockLocked]. Unavailable and unlocked never gate.
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

/// Once-per-container guard so the soft-update prompt never nags within a
/// single session; scoped to the [ProviderContainer] so it resets per test.
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
        // Re-check here, not only synchronously above: go_router can
        // re-evaluate the redirect twice in the same frame, scheduling two
        // post-frame callbacks that both pass the earlier guard. The first to
        // run flips this flag so the dialog never stacks.
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
    // Store deep-link is best-effort; never break the hard-block UI on failure.
  }
}

/// True when a passcode is configured AND [PasscodeState.requiresChallenge]
/// (isSet && armed && not in brute-force lockout). AutoLockController arms the
/// passcode on idle timeout / background return.
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

/// Belt-and-suspenders guard against the passcode gate looping on its own
/// entry/setup routes (neither is a shell-tab destination, so the shell-tab
/// guard already short-circuits).
bool _isPasscodeRoute(String path) =>
    path == AppRoutes.passcodeEntryPath || path == AppRoutes.passcodeSetupPath;
