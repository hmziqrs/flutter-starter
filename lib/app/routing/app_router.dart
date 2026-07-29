import 'dart:async';
import 'dart:math' as math;

import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/diagnostics/diagnostics_page.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/app/routing/otp_purpose.dart';
import 'package:starter/app/routing/route_error_page.dart';
import 'package:starter/app/shell/app_shell.dart';
import 'package:starter/app/shell/cross_fading_branch_container.dart';
import 'package:starter/features/auth/auth_attempt_tracker.dart';
import 'package:starter/features/auth/forgot_password_page.dart';
import 'package:starter/features/auth/login_page.dart';
import 'package:starter/features/auth/login_presentation_state.dart';
import 'package:starter/features/auth/otp_controller.dart';
import 'package:starter/features/auth/otp_page.dart';
import 'package:starter/features/auth/register_page.dart';
import 'package:starter/features/auth/reset_password_page.dart';
import 'package:starter/features/dev_gallery/gallery_registry.dart';
import 'package:starter/features/dev_gallery/screen_gallery_page.dart';
import 'package:starter/features/force_update/force_update_page.dart';
import 'package:starter/features/force_update/force_update_state.dart';
import 'package:starter/features/force_update/soft_update_dialog.dart';
import 'package:starter/features/force_update/update_requirement.dart';
import 'package:starter/features/force_update/version_gate_providers.dart';
import 'package:starter/features/home/home_page.dart';
import 'package:starter/features/home/home_view_data.dart';
import 'package:starter/features/onboarding/onboarding_page.dart';
import 'package:starter/features/pricing/paywall_page.dart';
import 'package:starter/features/pricing/plan_view_data.dart';
import 'package:starter/features/pricing/pricing_page.dart';
import 'package:starter/features/profile/profile_repository.dart';
import 'package:starter/features/profile/profile_view_data.dart';
import 'package:starter/features/profile/update_profile_page.dart';
import 'package:starter/features/search/search_page.dart';
import 'package:starter/features/security/biometric_lock_page.dart';
import 'package:starter/features/security/biometric_unlock_controller.dart';
import 'package:starter/features/security/passcode_controller.dart';
import 'package:starter/features/security/passcode_page.dart';
import 'package:starter/features/session/auth_repository.dart';
import 'package:starter/features/session/auth_session.dart';
import 'package:starter/features/session/session_controller.dart';
import 'package:starter/features/settings/accessibility_settings_page.dart';
import 'package:starter/features/settings/license_page.dart';
import 'package:starter/features/settings/settings_controller.dart';
import 'package:starter/features/settings/settings_page.dart';
import 'package:starter/features/settings/settings_store.dart';
import 'package:starter/features/splash/splash_page.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/biometric/biometric_authenticator.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';
import 'package:starter/shared/adaptive/app_layout_class.dart';
import 'package:starter/shared/adaptive/app_layout_provider.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/escape_dismissible_overlay.dart';
import 'package:url_launcher/url_launcher.dart';

GoRouter buildAppRouter({
  required AppConfig config,
  String initialLocation = AppRoutes.splashPath,
  bool hasCompletedOnboarding = false,
  List<NavigatorObserver> observers = const <NavigatorObserver>[],
}) {
  // The cold-start seed mirrors AppDependencies.initialSettings
  // .hasCompletedOnboarding and is threaded from createApplication -> App ->
  // _AppView. It is a fallback for test harnesses that build the router
  // without a ProviderScope above MaterialApp.router; the live redirect reads
  // settingsControllerProvider so the in-session Skip path observes the
  // optimistic write on the same tick (see _redirectSettingsDeepLinks).
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      StatefulShellRoute(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        navigatorContainerBuilder: crossFadingBranchContainer,
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRoutes.home,
                path: AppRoutes.homePath,
                builder: (context, state) => HomePage(
                  viewData: HomeViewData.defaults(),
                  onOpenProfile: () => context.pushNamed(AppRoutes.updateProfile),
                  onOpenPricing: () => _goTab(context, 1),
                  onOpenSettings: () => _goTab(context, 2),
                  onOpenLogin: () => context.pushNamed(AppRoutes.login),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRoutes.pricing,
                path: AppRoutes.pricingPath,
                builder: (context, state) => PricingPage(
                  plans: PricingFixtures.standard(context.t),
                  onSelectPlan: (plan, _) => _showInformationDialog(
                    context,
                    title: context.t.pricing.choosePlan(plan: plan.name),
                    body: context.t.pricing.staticPurchaseNotice,
                  ),
                  onOpenTerms: () => _showInformationDialog(
                    context,
                    title: context.t.pricing.terms,
                  ),
                  onOpenPrivacy: () => _showInformationDialog(
                    context,
                    title: context.t.pricing.privacy,
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRoutes.settings,
                path: AppRoutes.settingsPath,
                builder: (context, state) => _settingsPage(
                  context,
                  SettingsSection.tryParse(state.uri.queryParameters['section']),
                ),
              ),
              GoRoute(
                name: AppRoutes.appearanceSettings,
                path: AppRoutes.appearanceSettingsPath,
                builder: (context, state) => _settingsPage(context, SettingsSection.appearance),
              ),
              GoRoute(
                name: AppRoutes.languageSettings,
                path: AppRoutes.languageSettingsPath,
                builder: (context, state) => _settingsPage(context, SettingsSection.language),
              ),
              GoRoute(
                name: AppRoutes.accessibilitySettings,
                path: AppRoutes.accessibilitySettingsPath,
                builder: (context, state) => const AccessibilitySettingsPage(),
              ),
              GoRoute(
                name: AppRoutes.aboutLicense,
                path: AppRoutes.aboutLicensePath,
                // In-shell license route (license-share-update spec). Pushed
                // from the settings "About" tile; thin wrapper over Flutter's
                // local license registry (backend-free).
                builder: (context, state) => const AboutLicensePage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        name: AppRoutes.splash,
        path: AppRoutes.splashPath,
        builder: (context, state) => SplashPage(
          // SplashPage receives the navigation callback (never calls go_router
          // directly, per the root contract). On resolve it goes to home; the
          // existing C5 onboarding redirect then sends fresh installs to
          // /onboarding (home '/' is a shell-tab destination and gates when
          // !hasCompletedOnboarding), and the HARD update-blocker redirect
          // (already first in _redirectSettingsDeepLinks) wins over both.
          onComplete: (_) => context.goNamed(AppRoutes.home),
        ),
      ),
      GoRoute(
        name: AppRoutes.onboarding,
        path: AppRoutes.onboardingPath,
        builder: (context, state) => OnboardingPage(
          onSkip: () => _completeOnboardingAndGoHome(context),
          onOpenPaywall: () => context.goNamed(AppRoutes.onboardingPaywall),
        ),
      ),
      GoRoute(
        name: AppRoutes.onboardingPaywall,
        path: AppRoutes.onboardingPaywallPath,
        builder: (context, state) => PaywallPage(
          plans: PricingFixtures.standard(context.t),
          onSkip: () => _completeOnboardingAndGoHome(context),
          onContinue: (_, _) => _completeOnboardingAndGoHome(context),
          onRestore: () => _showInformationDialog(
            context,
            title: context.t.pricing.restore,
            body: context.t.pricing.restoreUnavailable,
          ),
          onOpenTerms: () => _showInformationDialog(
            context,
            title: context.t.pricing.terms,
          ),
          onOpenPrivacy: () => _showInformationDialog(
            context,
            title: context.t.pricing.privacy,
          ),
        ),
      ),
      GoRoute(
        name: AppRoutes.forceUpdate,
        path: AppRoutes.forceUpdatePath,
        builder: (context, state) {
          final requirement = ProviderScope.containerOf(
            context,
            listen: false,
          ).read(versionCheckProvider).value;
          final hard = requirement is UpdateRequirementHard
              ? requirement
              : const UpdateRequirementHard(
                  minVersion: '',
                  latestVersion: '',
                  storeUrl: '',
                );
          return ForceUpdatePage(
            state: ForceUpdateState.from(hard),
            onUpdateNow: () => unawaited(_launchStoreUrl(hard.storeUrl)),
          );
        },
      ),
      GoRoute(
        name: AppRoutes.biometricLock,
        path: AppRoutes.biometricLockPath,
        // Top-level (outside the shell) like /force-update and the auth routes:
        // a full-screen gate. The C5 redirect sends protected destinations here
        // when biometric unlock is enabled and the lock subsystem is locked.
        builder: (context, state) => BiometricLockPage(
          onUnlocked: () => context.goNamed(AppRoutes.home),
          // Disables the biometric-unlock setting (the only thing keeping the
          // user on /lock) and navigates to home. This gives the Unavailable
          // state a real escape: a device whose biometric disappeared post-
          // enable is not stranded (the redirect's live read sees
          // biometricUnlockEnabled flip to false on the same tick and stops
          // gating). When a passcode is configured the fallback hands off to
          // the passcode entry page instead (the biometric 'unavailable ->
          // passcode' seam per the pin-autolock spec).
          onUseFallback: () => _useBiometricFallback(context),
        ),
      ),
      GoRoute(
        name: AppRoutes.passcodeEntry,
        path: AppRoutes.passcodeEntryPath,
        // Top-level (outside the shell) like /lock and /force-update: a
        // full-screen gate. The C5 redirect sends protected destinations here
        // when passcode protection is enabled and the passcode requires a
        // challenge (armed by AutoLockController on idle timeout / background
        // return). The entry surface is a hard gate: it has no back/escape
        // navigation until the passcode verifies (or the user disables).
        builder: (context, state) => PasscodePage(
          mode: PasscodePageMode.entry,
          onUnlocked: () => context.goNamed(AppRoutes.home),
          onDisable: () => _disablePasscodeAndGoHome(context),
        ),
      ),
      GoRoute(
        name: AppRoutes.passcodeSetup,
        path: AppRoutes.passcodeSetupPath,
        // Pushed from the settings security tile when the user turns passcode
        // protection on. After set() the controller is disarmed in-session so
        // onSetupComplete returns to settings.
        builder: (context, state) => PasscodePage(
          mode: PasscodePageMode.setup,
          onUnlocked: () => context.goNamed(AppRoutes.home),
          onSetupComplete: () => _finishPasscodeSetup(context),
        ),
      ),
      GoRoute(
        name: AppRoutes.search,
        path: AppRoutes.searchPath,
        // Top-level full-screen flow (outside the StatefulShellRoute), per
        // architecture.md. No redirect: /search is not a shell-tab destination
        // and not auth-required, so it falls through the C5 redirect cleanly.
        builder: (context, state) => SearchPage(
          onBack: () {
            final router = GoRouter.of(context);
            if (router.canPop()) {
              router.pop();
            } else {
              context.goNamed(AppRoutes.home);
            }
          },
        ),
      ),
      GoRoute(
        name: AppRoutes.login,
        path: AppRoutes.loginPath,
        builder: (context, state) => _LoginRoutePage(
          passwordResetComplete: state.uri.queryParameters['status'] == _passwordResetComplete,
        ),
      ),
      GoRoute(
        name: AppRoutes.register,
        path: AppRoutes.registerPath,
        builder: (context, state) => RegisterPage(
          // Registration is backend-dependent (account creation + OTP issue).
          // The AuthRepository port does not expose a register method, and the
          // no-backend default cannot create an account — surfacing
          // `common.notConnected` here is the honest C13 stance. Navigation to
          // the OTP step fires only when a consumer wires a real registration
          // endpoint; the dev-gallery exercises RegisterPage directly with its
          // own callbacks so the fixture flow stays intact.
          onSubmit: (value) async {
            // Wire registration through the AuthRepository (C13 — never fake
            // success). The no-backend default throws AuthException.notConnected
            // and surfaces the dialog; with a backend configured it creates the
            // pending account + issues the registration OTP, and we navigate to
            // the OTP step threading the email as the identifier.
            final container = ProviderScope.containerOf(context, listen: false);
            try {
              await container
                  .read(authRepositoryProvider)
                  .register(
                    credentials: AuthCredentials(email: value.email, password: value.password),
                    displayName: value.displayName,
                  );
              if (!context.mounted) return;
              GoRouter.of(context).goNamed(
                AppRoutes.otp,
                pathParameters: <String, String>{
                  'purpose': OtpPurpose.registration.pathSegment,
                },
                queryParameters: <String, String>{'identifier': value.email},
              );
            } on AuthException {
              if (!context.mounted) return;
              _showInformationDialog(
                context,
                title: context.t.common.legalPlaceholderTitle,
                body: context.t.common.notConnected,
              );
            }
          },
          onLogin: () => _returnToLogin(context),
          onOpenTerms: () => _showInformationDialog(
            context,
            title: context.t.auth.register.terms,
          ),
          onOpenPrivacy: () => _showInformationDialog(
            context,
            title: context.t.auth.register.privacy,
          ),
        ),
      ),
      GoRoute(
        name: AppRoutes.forgotPassword,
        path: AppRoutes.forgotPasswordPath,
        builder: (context, state) => ForgotPasswordPage(
          onSubmit: (_) => unawaited(_openPasswordResetOtp(context)),
          onLogin: () => _finishPasswordResetFlow(
            context,
            _PasswordResetFlowResult.returnToLogin,
          ),
        ),
      ),
      GoRoute(
        name: AppRoutes.otp,
        path: AppRoutes.otpPath,
        builder: (context, state) {
          final purpose = OtpPurpose.tryParse(state.pathParameters['purpose']);
          if (purpose == null) {
            return _routeErrorPage(
              context,
              state,
              message: context.t.routeError.invalidOtpPurpose,
            );
          }
          // MFA is the controller-driven runtime path: the page reads live
          // state from `otpControllerProvider` (countdown, lockout, verify /
          // resend transitions) and the controller surfaces `globalFailure`
          // honestly under the no-backend default. Registration / password-
          // reset keep their existing fixture path so the dev-gallery stays
          // deterministic (C5: reuse the existing OTP route, no new redirect).
          if (purpose == OtpPurpose.mfa || purpose == OtpPurpose.registration) {
            return _OtpRoutePage(
              purpose: purpose,
              identifier: state.uri.queryParameters['identifier'] ?? '',
            );
          }
          return OtpPage(
            purpose: purpose,
            onSubmit: (_) => switch (purpose) {
              OtpPurpose.registration => context.goNamed(AppRoutes.home),
              OtpPurpose.passwordReset => unawaited(_openResetPassword(context)),
              OtpPurpose.mfa => context.goNamed(AppRoutes.home),
            },
            onResend: () => _showInformationDialog(
              context,
              title: context.t.auth.otp.resend,
              body: context.t.common.notConnected,
            ),
          );
        },
      ),
      GoRoute(
        name: AppRoutes.resetPassword,
        path: AppRoutes.resetPasswordPath,
        builder: (context, state) => ResetPasswordPage(
          onSubmit: (_) => _finishPasswordResetFlow(
            context,
            _PasswordResetFlowResult.completed,
          ),
          onLogin: () => _finishPasswordResetFlow(
            context,
            _PasswordResetFlowResult.returnToLogin,
          ),
        ),
      ),
      GoRoute(
        name: AppRoutes.updateProfile,
        path: AppRoutes.updateProfilePath,
        // Auth-gated (see _isAuthRequiredDestination): a session is held when
        // this route builds. The route page loads the profile draft from the
        // backend over the access token and degrades to ProfileDraft.defaults()
        // on any failure (graceful — never crashes the page).
        builder: (context, state) => const _UpdateProfileRoutePage(),
      ),
      if (config.developmentToolsEnabled) ...[
        GoRoute(
          name: AppRoutes.developmentScreens,
          path: AppRoutes.developmentScreensPath,
          builder: (context, state) => ScreenGalleryPage(
            cases: buildGalleryRegistry(config: config),
          ),
        ),
        GoRoute(
          name: AppRoutes.diagnostics,
          path: AppRoutes.diagnosticsPath,
          builder: (context, state) => DiagnosticsPage(config: config),
        ),
      ],
    ],
    errorBuilder: _routeErrorPage,
    observers: observers,
    redirect: (context, state) => _redirectSettingsDeepLinks(
      context,
      state,
      hasCompletedOnboardingSeed: hasCompletedOnboarding,
    ),
  );
}

// One redirect (C5): predicates chained in priority order. Each block returns
// the first non-null target. Behavioral precedence: update-blocker HARD ->
// onboarding -> SESSION -> BIOMETRIC. Code order differs from precedence only
// for the session gate, which is guarded by `hasCompletedOnboarding` so the
// onboarding gate still wins for fresh installs (see block 3a below).
//
//   (1)  update-blocker HARD (wins over everything)
//   (2)  settings deep-link normalization
//   (3a) SESSION auth-required gate (only when onboarding is complete; sends
//        an anonymous user hitting an auth-only destination to /auth/login)
//   (3b) onboarding gate (shell-tab destinations -> /onboarding when unset)
//   (4)  BIOMETRIC gate (locked subsystem -> /lock for shell-tab destinations)
//
// Update-blocker HARD must run first so a hard block wins over onboarding and
// settings normalization. SOFT never redirects — it triggers a post-frame
// dialog gated by a once-per-process flag plus the snooze timestamp. NONE /
// loading / error fall through.
String? _redirectSettingsDeepLinks(
  BuildContext context,
  GoRouterState state, {
  bool hasCompletedOnboardingSeed = false,
}) {
  final path = state.uri.path;

  // (1) Update-blocker HARD: any route other than /force-update redirects to
  // /force-update; on /force-update returns null (no loop).
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

  // (2) Existing settings deep-link normalization.
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

  // (3a) Onboarding gate. FIRST in this block so the evaluated order matches
  // the documented C5 precedence (update -> ONBOARDING -> session -> biometric
  // -> passcode). Deep links and auth flows must not be hijacked into an
  // onboarding loop, so skip when already on an onboarding or auth route.
  if (_isOnboardingOrAuthRoute(path)) {
    return null;
  }
  // Read LIVE controller state so the in-session Skip -> markOnboardingComplete
  // -> goName(home) path is observable here on the same tick. A captured bool
  // would re-evaluate against the stale pre-mark value and bounce home ->
  // onboarding until relaunch. The seed is a fallback for test harnesses that
  // build the router without a ProviderScope above MaterialApp.router.
  final hasCompleted = _readLiveHasCompletedOnboarding(context) ?? hasCompletedOnboardingSeed;
  // Only the shell-tab destinations gate through onboarding. Detail routes
  // (/profile/edit, /dev/*) are reachable from the shell and only render after
  // the shell itself has cleared onboarding, so they do not redirect here;
  // /profile/edit falls through to the session gate (3b) below.
  if (_isShellTabDestination(path) && !hasCompleted) {
    return AppRoutes.onboardingPath;
  }

  // (3b) Session auth-required gate. Composed into the single C5 redirect
  // (no new callback). Reuses AppRoutes.login — NO new route. Evaluated AFTER
  // the onboarding gate so onboarding wins for fresh installs (the precedence
  // chain is update -> onboarding -> SESSION). An auth-only destination (today:
  // /profile/edit, reached from the settings shell tab) accessed by an
  // anonymous user is sent to /auth/login. The hasCompletedOnboarding guard is
  // defense-in-depth: a not-onboarded user reaching an auth-required detail
  // route (only possible in a test harness without a ProviderScope) is not
  // bounced to login before completing onboarding.
  if (_isAuthRequiredDestination(path) && hasCompleted) {
    final session = _readLiveSession(context) ?? const AuthAnonymous();
    if (session is! AuthAuthenticated) {
      return AppRoutes.loginPath;
    }
  }

  // Non-shell-tab, non-auth-required detail routes (/dev/*) stop here — they
  // are reachable only from the shell (which has cleared onboarding) and do not
  // re-gate through biometric/passcode independently.
  if (!_isShellTabDestination(path)) {
    return null;
  }
  // (4) BIOMETRIC gate. A returning user (onboarding complete) on a shell-tab
  // destination whose biometric unlock is enabled AND whose lock subsystem is
  // BiometricLockLocked is sent to /lock. Unavailable never redirects (the
  // predicate acts only on BiometricLockLocked), so a device without biometric
  // is never looped into a prompt that cannot succeed. /lock itself is not a
  // shell-tab destination, so it already returned null above (no loop).
  if (_readLiveBiometricUnlockActive(context)) {
    return AppRoutes.biometricLockPath;
  }
  // (5) PASSCODE gate (pin-autolock). The passcode is the LAST gate, placed
  // AFTER biometric: a user with both enabled is sent to biometric first
  // (block 4), and the biometric page's onUseFallback hands off to /passcode
  // via _useBiometricFallback. AUTO-LOCK arms the passcode state through
  // AutoLockController.arm (idle timeout / background return), which flips
  // PasscodeState.enabled to true, so requiresChallenge becomes true and this
  // block fires on the next redirect evaluation. requiresChallenge =
  // isSet && enabled(armed) && lockedUntil == null. During an ACTIVE brute-
  // force lockout lockedUntil != null so requiresChallenge is false, but the
  // user is already on /passcode (a hard gate with no escape nav until
  // verified), so this never creates an escape hatch. /passcode and
  // /settings/security/passcode are not shell-tab destinations, so they
  // already returned null above (no loop); the explicit _isPasscodeRoute
  // guard is belt-and-suspenders.
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

/// Reads LIVE session state so an in-session login/logout is observable on the
/// same tick. Returns null on the test-harness no-scope case (mirrors
/// [_readLiveHasCompletedOnboarding]).
AuthSession? _readLiveSession(BuildContext context) {
  try {
    final container = ProviderScope.containerOf(context, listen: false);
    return container.read(sessionControllerProvider);
  } on Object {
    return null;
  }
}

/// True when the biometric gate should fire: biometric unlock is enabled in
/// settings AND the lock subsystem is [BiometricLockLocked]. Returns false on
/// the test-harness no-scope case so tests that do not wire the controllers
/// never trigger the gate. Unavailable and unlocked never gate.
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
/// single session (the snooze timestamp covers cross-launch suppression).
/// Scoped to the [ProviderContainer] rather than a module-level global so it
/// resets per test (checklist #4 — composition root confined, no globals).
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
        // Re-check the once-per-session flag HERE, not only synchronously above:
        // go_router can re-evaluate the single redirect twice in the same frame
        // (initial location + the refresh when versionCheck resolves), so two
        // evaluations each pass the synchronous guard and each schedule a
        // post-frame callback. The first callback to run flips this flag; the
        // sibling callback short-circuits here so the dialog never stacks.
        if (container.read(softUpdatePromptShownProvider)) {
          return;
        }
        // Mark the flag only when the dialog is actually presented, not before
        // the post-frame callback — a detection that races with
        // context.dispose() must not permanently suppress the dialog.
        container.read(softUpdatePromptShownProvider.notifier).markShown();
        unawaited(
          showSoftUpdateDialog(
            context,
            state: ForceUpdateState.from(requirement),
            onUpdate: () => unawaited(_launchStoreUrl(requirement.storeUrl)),
            onLater: () => store.writeString(SoftUpdateSnooze.key, SoftUpdateSnooze.encode()),
          ),
        );
      }),
    );
  });
}

Future<void> _launchStoreUrl(String storeUrl) async {
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

/// Disables the biometric-unlock setting and navigates to home. The optimistic
/// `state =` inside `SettingsController._replace` runs before the first await,
/// so the C5 redirect's live read sees `biometricUnlockEnabled` flip to false
/// on the same tick as `goNamed(home)` and stops gating.
void _disableBiometricAndGoHome(BuildContext context) {
  final container = ProviderScope.containerOf(context, listen: false);
  unawaited(
    container.read(settingsControllerProvider.notifier).setBiometricUnlockEnabled(enabled: false),
  );
  context.goNamed(AppRoutes.home);
}

/// True when a passcode is configured (settings.passcodeEnabled) AND the
/// passcode subsystem requires a challenge ([PasscodeState.requiresChallenge]:
/// isSet && armed && not in brute-force lockout). Returns false on the
/// test-harness no-scope case so unwired tests never trigger the gate. This is
/// the single predicate the C5 PASSCODE block reads; AUTO-LOCK arms the
/// passcode state via AutoLockController.arm so requiresChallenge becomes true
/// on idle timeout / background return.
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

/// True for the passcode entry + setup routes so the PASSCODE gate never loops
/// (both are full-screen gates, not shell-tab destinations, so the shell-tab
/// guard already short-circuits — this is belt-and-suspenders).
bool _isPasscodeRoute(String path) =>
    path == AppRoutes.passcodeEntryPath || path == AppRoutes.passcodeSetupPath;

/// Disables the passcode (clears the hash + armed flag in SecureStore) and the
/// settings toggle, then navigates to home. Wired to the entry surface's
/// onDisable escape hatch. The optimistic `state =` writes run before the first
/// await, so the redirect's live read sees requiresChallenge flip to false on
/// the same tick as goNamed(home) and stops gating. Mirrors
/// [_disableBiometricAndGoHome].
void _disablePasscodeAndGoHome(BuildContext context) {
  final container = ProviderScope.containerOf(context, listen: false);
  unawaited(container.read(passcodeControllerProvider.notifier).disable());
  unawaited(
    container.read(settingsControllerProvider.notifier).setPasscodeEnabled(enabled: false),
  );
  context.goNamed(AppRoutes.home);
}

/// Called after the setup surface accepts a confirmed passcode. After set() the
/// controller is disarmed in-session, so onSetupComplete returns to settings
/// (where the user came from). Falls back to home if settings is unreachable.
void _finishPasscodeSetup(BuildContext context) {
  context.goNamed(AppRoutes.settings);
}

/// Biometric 'unavailable -> passcode' handoff seam. When biometrics are
/// unavailable but a passcode is configured, navigate to the passcode entry
/// page; otherwise fall back to disabling biometric and going home. This
/// replaces the placeholder onUseFallback on the biometric lock page now that
/// pin-autolock ships.
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

/// Marks first-launch onboarding complete (optimistic in-memory write through
/// the settings controller) and then navigates to home. Called from every
/// home-navigating onboarding callback — OnboardingPage.onSkip, the paywall
/// onContinue, and PaywallPage.onSkip — so the redirect's live read sees
/// hasCompletedOnboarding = true on the same tick as goNamed(home) and does
/// not bounce back into onboarding. Persistence is fire-and-forget: the
/// synchronous `state =` inside SettingsController._replace runs before the
/// first await, and a rollback on persistence failure only re-opens onboarding
/// on the next cold start (acceptable — the user already saw home).
void _completeOnboardingAndGoHome(BuildContext context) {
  final container = ProviderScope.containerOf(context, listen: false);
  unawaited(container.read(settingsControllerProvider.notifier).markOnboardingComplete());
  context.goNamed(AppRoutes.home);
}

const _passwordResetComplete = 'password-reset-complete';

enum _PasswordResetFlowResult {
  completed,
  returnToLogin,
}

class _LoginRoutePage extends ConsumerStatefulWidget {
  const _LoginRoutePage({required this.passwordResetComplete});

  final bool passwordResetComplete;

  @override
  ConsumerState<_LoginRoutePage> createState() => _LoginRoutePageState();
}

class _LoginRoutePageState extends ConsumerState<_LoginRoutePage> {
  late bool _passwordResetComplete = widget.passwordResetComplete;
  LoginPresentationStatus _status = LoginPresentationStatus.idle;
  // Auth-ratelimit (C1). The shared AttemptTracker drives the live lockout
  // seconds + attempts-remaining surfaced by the page. Mirrors the OTP
  // controller's recordFailure/recordSuccess wiring so login, OTP, and pin-
  // autolock share one schedule (the named-consumer list in auth-ratelimit.md).
  int _lockedSeconds = 0;
  int _attemptsRemaining = 0;

  @override
  void didUpdateWidget(covariant _LoginRoutePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.passwordResetComplete != oldWidget.passwordResetComplete) {
      _passwordResetComplete = widget.passwordResetComplete;
    }
  }

  /// Builds the presentation, threading the tracker-derived lockout fields so
  /// the page's existing countdown + attempts-remaining UI lights up the moment
  /// a failure escalates to a lock.
  LoginPresentationState _presentation() {
    if (_passwordResetComplete) {
      return LoginPresentationState.success(
        successMessage: context.t.auth.resetPassword.success,
      );
    }
    return switch (_status) {
      LoginPresentationStatus.locked => LoginPresentationState.locked(
        lockedSeconds: _lockedSeconds,
        attemptsRemaining: _attemptsRemaining,
      ),
      _ => LoginPresentationState(
        status: _status,
        attemptsRemaining: _attemptsRemaining,
      ),
    };
  }

  Future<void> _openForgotPassword() async {
    final result = await context.pushNamed<_PasswordResetFlowResult>(
      AppRoutes.forgotPassword,
    );
    if (!mounted || result != _PasswordResetFlowResult.completed) {
      return;
    }
    setState(() => _passwordResetComplete = true);
  }

  @override
  Widget build(BuildContext context) {
    return LoginPage(
      presentation: _presentation(),
      onSubmit: (value) async {
        // Wire authentication through the SessionController (C13 — never fake
        // success). The no-backend default (InMemoryAuthRepository.login)
        // throws AuthException.notConnected, which surfaces as globalFailure.
        // Navigation to home fires only on a real AuthAuthenticated result.
        final router = GoRouter.of(context);
        // Auth-ratelimit (C1): gate the submit on a live lock check, mirroring
        // otp_controller's `state.isLocked`. If the identifier is mid-lockout
        // (e.g. a prior failure on this or the OTP surface), re-surface the
        // locked presentation and refuse the call rather than burning a request
        // the server would 429 anyway.
        final tracker = ref.read(attemptTrackerProvider);
        final existing = tracker.read(value.email);
        final now = clock.now();
        if (existing != null && existing.isLockedAt(now)) {
          if (!mounted) return;
          setState(() {
            _status = LoginPresentationStatus.locked;
            _lockedSeconds = existing.lockedSecondsAt(now);
            _attemptsRemaining = existing.attemptsRemaining;
          });
          return;
        }
        setState(() => _status = LoginPresentationStatus.submitting);
        try {
          await ref
              .read(sessionControllerProvider.notifier)
              .login(
                AuthCredentials(email: value.email, password: value.password),
              );
          if (!mounted) return;
          final session = ref.read(sessionControllerProvider);
          if (session is AuthAuthenticated) {
            // A success clears the shared tracker so an eventual typo is not
            // one failure away from a lockout (mirrors otp_controller.verify).
            tracker.recordSuccess(value.email);
            router.goNamed(AppRoutes.home);
          } else {
            // The repository returned without error but did not authenticate
            // — never navigate as if it did (C13).
            setState(() => _status = LoginPresentationStatus.globalFailure);
          }
        } on AuthException {
          if (!mounted) return;
          // Record the failure against the shared schedule. If the schedule
          // locks the identifier, surface the `locked` presentation (the page's
          // countdown + attempts-remaining UI already exists); otherwise stay
          // on globalFailure with the remaining free attempts surfaced.
          final attempt = tracker.recordFailure(value.email);
          final lockedNow = clock.now();
          setState(() {
            _attemptsRemaining = math.max(0, attempt.attemptsRemaining);
            _status = attempt.isLockedAt(lockedNow)
                ? LoginPresentationStatus.locked
                : LoginPresentationStatus.globalFailure;
            if (attempt.isLockedAt(lockedNow)) {
              _lockedSeconds = attempt.lockedSecondsAt(lockedNow);
            }
          });
        }
      },
      onForgotPassword: () => unawaited(_openForgotPassword()),
      onRegister: () => context.pushNamed(AppRoutes.register),
    );
  }
}

Future<void> _openPasswordResetOtp(BuildContext context) async {
  final result = await context.push<_PasswordResetFlowResult>(
    AppRoutes.otpLocation(OtpPurpose.passwordReset),
  );
  if (result != null && context.mounted) {
    _finishPasswordResetFlow(context, result);
  }
}

Future<void> _openResetPassword(BuildContext context) async {
  final result = await context.pushNamed<_PasswordResetFlowResult>(
    AppRoutes.resetPassword,
  );
  if (result != null && context.mounted) {
    _finishPasswordResetFlow(context, result);
  }
}

void _finishPasswordResetFlow(
  BuildContext context,
  _PasswordResetFlowResult result,
) {
  final router = GoRouter.of(context);
  if (router.canPop()) {
    router.pop(result);
    return;
  }

  context.goNamed(
    AppRoutes.login,
    queryParameters: result == _PasswordResetFlowResult.completed
        ? {'status': _passwordResetComplete}
        : const {},
  );
}

void _returnToLogin(BuildContext context) {
  final router = GoRouter.of(context);
  if (router.canPop()) {
    router.pop();
    return;
  }
  context.goNamed(AppRoutes.login);
}

SettingsPage _settingsPage(BuildContext context, SettingsSection? section) {
  return SettingsPage(
    section: section,
    onOpenAppearance: () => _openSettingsSection(context, SettingsSection.appearance),
    onOpenLanguage: () => _openSettingsSection(context, SettingsSection.language),
    onOpenAccessibility: () => context.pushNamed(AppRoutes.accessibilitySettings),
    onOpenAccount: () => _openSettingsSection(context, SettingsSection.account),
    onOpenSubscription: () => _openSettingsSection(context, SettingsSection.subscription),
    onOpenPrivacyAbout: () => _openSettingsSection(context, SettingsSection.privacyAbout),
    onOpenProfile: () => context.pushNamed(AppRoutes.updateProfile),
    onOpenLogin: () => context.pushNamed(AppRoutes.login),
    onOpenPricing: () => _goTab(context, 1),
    onOpenTerms: () => _showInformationDialog(
      context,
      title: context.t.settings.terms,
    ),
    onOpenPrivacy: () => _showInformationDialog(
      context,
      title: context.t.settings.privacy,
    ),
    // license-share-update: route the "License" tile to the in-shell
    // aboutLicense route (Flutter's local license registry; backend-free).
    onOpenLicense: () => context.pushNamed(AppRoutes.aboutLicense),
    loadBuildLabel: () async => (await AppBuildInfo.load()).displayValue,
  );
}

void _goTab(BuildContext context, int index) {
  // Returns StatefulNavigationShellState (route.dart:1329), which owns both
  // goBranch and currentIndex.
  final shell = StatefulNavigationShell.of(context);
  shell.goBranch(index, initialLocation: index == shell.currentIndex);
}

void _openSettingsSection(BuildContext context, SettingsSection section) {
  // Compact drills into a dedicated path where one exists; wide always selects
  // the pane in place via ?section=, keeping the /settings page key.
  final (String name, Map<String, dynamic> queryParameters) = switch (section) {
    SettingsSection.appearance => (AppRoutes.appearanceSettings, const {}),
    SettingsSection.language => (AppRoutes.languageSettings, const {}),
    _ => (AppRoutes.settings, {'section': section.parameter}),
  };

  final layoutClass = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(appLayoutClassProvider);

  if (layoutClass == AppLayoutClass.compact) {
    final target = Uri.parse(
      context.namedLocation(name, queryParameters: queryParameters),
    );
    if (GoRouterState.of(context).uri == target) return;
    unawaited(context.pushNamed<void>(name, queryParameters: queryParameters));
    return;
  }

  final wideTarget = Uri.parse(
    context.namedLocation(
      AppRoutes.settings,
      queryParameters: {'section': section.parameter},
    ),
  );
  if (GoRouterState.of(context).uri == wideTarget) return;
  context.replaceNamed(
    AppRoutes.settings,
    queryParameters: {'section': section.parameter},
  );
}

void _showInformationDialog(
  BuildContext context, {
  required String title,
  String? body,
}) {
  unawaited(
    showFDialog<void>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      builder: (context, style, animation) => EscapeDismissibleOverlay(
        child: FDialog(
          key: const ValueKey('information-dialog'),
          animation: animation,
          builder: (context, style) => Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: context.theme.typography.display.xl),
                const SizedBox(height: AppSpacing.md),
                Text(body ?? context.t.common.legalPlaceholderBody),
                const SizedBox(height: AppSpacing.xl),
                FButton(
                  key: const ValueKey('information-dialog-close'),
                  autofocus: true,
                  onPress: () => Navigator.of(context).pop(),
                  child: Text(context.t.common.close),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

RouteErrorPage _routeErrorPage(
  BuildContext context,
  GoRouterState state, {
  String? message,
}) {
  final router = GoRouter.of(context);
  return RouteErrorPage(
    location: state.uri.toString(),
    message: message,
    onHome: () => context.goNamed(AppRoutes.home),
    onBack: () {
      if (router.canPop()) {
        router.pop();
      }
    },
  );
}

/// Controller-driven MFA OTP route page.
///
/// Wires the static [OtpPage] (the dev-gallery fixture surface) to the live
/// [OtpController] family for the MFA runtime path. The controller owns the
/// expiry `Timer`, the verify / resend state machine, and the auth-ratelimit
/// handoff (locked state). The no-backend default surfaces `globalFailure`
/// honestly: the controller calls `requestIssue` on mount, the
/// `InMemoryOtpRepository` throws `OtpRepositoryException.notConnected`, and
/// the page renders the `common.notConnected` alert (C2 — never fakes a code).
///
/// A successful verify navigates to home. Navigation never gates on animation
/// (the page reads `state` and navigates on the success transition).
class _OtpRoutePage extends ConsumerStatefulWidget {
  const _OtpRoutePage({required this.purpose, required this.identifier});

  /// Which OTP flow this page drives. `mfa` verifies and navigates home;
  /// `registration` additionally publishes the session the backend issued
  /// inline on a valid verify (the account is activated server-side and the
  /// session arrives on `OtpControllerState.session`).
  final OtpPurpose purpose;

  /// The account identifier the code was issued for (email), sourced from the
  /// `identifier` query parameter (the login / register flows push it here).
  final String identifier;

  @override
  ConsumerState<_OtpRoutePage> createState() => _OtpRoutePageState();
}

class _OtpRoutePageState extends ConsumerState<_OtpRoutePage> {
  @override
  void initState() {
    super.initState();
    // Kick off the issue request post-frame so the freshly created
    // ProviderScope is used. Fire-and-forget: the controller surfaces the
    // outcome (success / globalFailure) through state.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final key = (purpose: widget.purpose, identifier: widget.identifier);
      unawaited(ref.read(otpControllerProvider(key).notifier).requestIssue());
    });
  }

  @override
  Widget build(BuildContext context) {
    final key = (purpose: widget.purpose, identifier: widget.identifier);
    final state = ref.watch(otpControllerProvider(key));
    final controller = ref.read(otpControllerProvider(key).notifier);
    return OtpPage(
      purpose: widget.purpose,
      // Merge the controller's live `remainingSeconds` into the static
      // presentation so the page's countdown + lockout rendering observes the
      // real values without the page reaching into the controller directly.
      presentation: state.presentation.copyWithRemainingSeconds(state.remainingSeconds),
      onSubmit: (value) async {
        final ok = await controller.verify(value.code);
        if (!ok || !mounted) {
          return;
        }
        // Registration: the backend activated the account and returned a
        // session inline on the valid verify — publish it before navigating
        // home so the auth-required gates (/profile/edit) pass. MFA carries no
        // session (the user authenticated through login, not registration).
        if (widget.purpose == OtpPurpose.registration) {
          final session = ref.read(otpControllerProvider(key)).session;
          if (session != null) {
            await ref.read(sessionControllerProvider.notifier).establish(session);
            if (!mounted) return;
          }
        }
        // Navigation never gates on animation; the controller's success
        // transition is observed synchronously, and `mounted` guards the
        // post-await context use.
        // ignore: use_build_context_synchronously
        context.goNamed(AppRoutes.home);
      },
      onResend: controller.resend,
    );
  }
}

/// Auth-gated profile-edit route page.
///
/// Loads the editable profile draft from the backend over the authenticated
/// session's access token and degrades to [ProfileDraft.defaults] on any
/// failure (transport / unaccepted session / no backend) so the page never
/// crashes. `onSave` persists the draft through the profile port and surfaces a
/// typed success / notConnected dialog. The avatar-pick flow is preserved
/// verbatim from the static phase.
class _UpdateProfileRoutePage extends StatefulWidget {
  const _UpdateProfileRoutePage();

  @override
  State<_UpdateProfileRoutePage> createState() => _UpdateProfileRoutePageState();
}

class _UpdateProfileRoutePageState extends State<_UpdateProfileRoutePage> {
  late final Future<ProfileDraft> _initialDraftLoad;

  @override
  void initState() {
    super.initState();
    // The route is auth-gated so a session is held; read its access token and
    // kick off the load once. `ProviderScope.containerOf(listen: false)` uses
    // findAncestorWidgetOfExactType, which is safe to call in initState. Any
    // failure resolves the future with an error and the FutureBuilder degrades
    // to ProfileDraft.defaults() (graceful — never a half-built page).
    final container = ProviderScope.containerOf(context, listen: false);
    final session = container.read(sessionControllerProvider);
    final accessToken = session is AuthAuthenticated ? session.accessToken : '';
    _initialDraftLoad = container.read(profileRepositoryProvider).load(accessToken: accessToken);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProfileDraft>(
      future: _initialDraftLoad,
      builder: (context, snapshot) {
        // Degrade to the local default on pending or error (transport / 401 /
        // no backend) — never crash the page. With the no-backend default the
        // load throws ProfileException.notConnected, so this is the path taken.
        final draft = snapshot.hasData ? snapshot.data! : const ProfileDraft.defaults();
        return UpdateProfilePage(
          initialDraft: draft,
          onSave: (draft) async {
            final container = ProviderScope.containerOf(context, listen: false);
            final session = container.read(sessionControllerProvider);
            final accessToken = session is AuthAuthenticated ? session.accessToken : '';
            try {
              await container
                  .read(profileRepositoryProvider)
                  .save(accessToken: accessToken, draft: draft);
              if (!context.mounted) return;
              _showInformationDialog(
                context,
                title: context.t.common.success,
                body: context.t.profile.update.saved,
              );
            } on ProfileException {
              if (!context.mounted) return;
              _showInformationDialog(
                context,
                title: context.t.common.legalPlaceholderTitle,
                body: context.t.common.notConnected,
              );
            }
          },
          // permissions-media avatar flow: preserved verbatim from the static
          // phase. A null result (denied / cancelled / no backend) surfaces the
          // honest `avatarUnavailable` copy.
          onAvatarPicked: (media) {
            if (media == null) {
              _showInformationDialog(
                context,
                title: context.t.profile.update.changeAvatar,
                body: context.t.profile.update.avatarUnavailable,
              );
            }
          },
        );
      },
    );
  }
}
