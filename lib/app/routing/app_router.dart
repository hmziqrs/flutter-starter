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
  // hasCompletedOnboarding is a fallback seed for test harnesses that build the
  // router without a ProviderScope; the live redirect reads
  // settingsControllerProvider instead (see _redirectSettingsDeepLinks).
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
                // Renders via SettingsPage (like appearance/language) so the wide
                // two-pane sidebar stays put on desktop.
                builder: (context, state) => _settingsPage(context, SettingsSection.accessibility),
              ),
              GoRoute(
                name: AppRoutes.aboutLicense,
                path: AppRoutes.aboutLicensePath,
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
          // Goes to home; the onboarding redirect then sends fresh installs to
          // /onboarding, and the HARD update-blocker redirect wins over both.
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
      GoRoute(
        name: AppRoutes.search,
        path: AppRoutes.searchPath,
        // Top-level, outside the StatefulShellRoute; not a shell-tab or
        // auth-required destination so it falls through the redirect untouched.
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
          // The no-backend default throws AuthException.notConnected and
          // surfaces the dialog; a real backend creates the pending account,
          // issues the registration OTP, and we navigate to the OTP step.
          onSubmit: (value) async {
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
          // MFA and registration are controller-driven: the page reads live
          // state from otpControllerProvider (countdown, lockout, verify/resend).
          // Password reset keeps the static fixture path.
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
        // this route builds.
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

// Single redirect: predicates chained in priority order, each returning the
// first non-null target. Precedence: update-blocker HARD -> settings
// normalization -> onboarding -> session -> biometric -> passcode. The
// onboarding gate runs before the session gate so a fresh install always sees
// onboarding first, even for an auth-required destination. SOFT never
// redirects — it triggers a post-frame dialog instead. NONE / loading / error
// fall through.
String? _redirectSettingsDeepLinks(
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

/// Marks onboarding complete (optimistic write) and navigates to home so the
/// redirect's live read does not bounce back into onboarding on the same tick.
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
  // Driven by the shared AttemptTracker (login, OTP, and pin-autolock share
  // one lockout schedule).
  int _lockedSeconds = 0;
  int _attemptsRemaining = 0;

  @override
  void didUpdateWidget(covariant _LoginRoutePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.passwordResetComplete != oldWidget.passwordResetComplete) {
      _passwordResetComplete = widget.passwordResetComplete;
    }
  }

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
        // Navigation to home fires only on a real AuthAuthenticated result;
        // the no-backend default throws AuthException.notConnected instead.
        final router = GoRouter.of(context);
        // Gate the submit on a live lock check: if the identifier is
        // mid-lockout, re-surface the locked presentation rather than burning
        // a request the server would 429 anyway.
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
            // Clear the shared tracker so an eventual typo is not one failure
            // away from a lockout.
            tracker.recordSuccess(value.email);
            router.goNamed(AppRoutes.home);
          } else {
            // Returned without error but did not authenticate — never
            // navigate as if it did.
            setState(() => _status = LoginPresentationStatus.globalFailure);
          }
        } on AuthException {
          if (!mounted) return;
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
    onOpenAccessibility: () => _openSettingsSection(context, SettingsSection.accessibility),
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
    onOpenLicense: () => context.pushNamed(AppRoutes.aboutLicense),
    loadBuildLabel: () async => (await AppBuildInfo.load()).displayValue,
  );
}

void _goTab(BuildContext context, int index) {
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

/// Wires the static [OtpPage] to the live [OtpController] family for the
/// MFA / registration runtime path (verify/resend state machine, lockout).
class _OtpRoutePage extends ConsumerStatefulWidget {
  const _OtpRoutePage({required this.purpose, required this.identifier});

  /// `mfa` verifies and navigates home; `registration` additionally publishes
  /// the session the backend issued inline on a valid verify.
  final OtpPurpose purpose;

  /// The account identifier the code was issued for, sourced from the
  /// `identifier` query parameter.
  final String identifier;

  @override
  ConsumerState<_OtpRoutePage> createState() => _OtpRoutePageState();
}

class _OtpRoutePageState extends ConsumerState<_OtpRoutePage> {
  @override
  void initState() {
    super.initState();
    // Post-frame, fire-and-forget: the controller surfaces the outcome
    // (success / globalFailure) through state.
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
      presentation: state.presentation.copyWithRemainingSeconds(state.remainingSeconds),
      onSubmit: (value) async {
        final ok = await controller.verify(value.code);
        if (!ok || !mounted) {
          return;
        }
        // Registration returns a session inline on a valid verify — publish it
        // before navigating home so the auth-required gates (/profile/edit)
        // pass. MFA carries no session (authenticated via login, not here).
        if (widget.purpose == OtpPurpose.registration) {
          final session = ref.read(otpControllerProvider(key)).session;
          if (session != null) {
            await ref.read(sessionControllerProvider.notifier).establish(session);
            if (!mounted) return;
          }
        }
        // `mounted` above already guards this post-await context use.
        // ignore: use_build_context_synchronously
        context.goNamed(AppRoutes.home);
      },
      onResend: controller.resend,
    );
  }
}

/// Auth-gated profile-edit route page. Loads the profile draft over the
/// session's access token and degrades to [ProfileDraft.defaults] on failure.
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
    // Auth-gated route, so a session is held; read its access token and kick
    // off the load once. Any failure resolves the future with an error and
    // the FutureBuilder degrades to ProfileDraft.defaults().
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
        // Degrade to the local default on pending or error — never crash.
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
