import 'dart:async';

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
import 'package:starter/features/auth/forgot_password_page.dart';
import 'package:starter/features/auth/login_page.dart';
import 'package:starter/features/auth/login_presentation_state.dart';
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
import 'package:starter/features/profile/profile_view_data.dart';
import 'package:starter/features/profile/update_profile_page.dart';
import 'package:starter/features/security/biometric_lock_page.dart';
import 'package:starter/features/security/biometric_unlock_controller.dart';
import 'package:starter/features/session/auth_session.dart';
import 'package:starter/features/session/session_controller.dart';
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
          onUseFallback: () => _showInformationDialog(
            context,
            title: context.t.common.legalPlaceholderTitle,
            body: context.t.common.notConnected,
          ),
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
          onSubmit: (_) => context.go(
            AppRoutes.otpLocation(OtpPurpose.registration),
          ),
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
          return OtpPage(
            purpose: purpose,
            onSubmit: (_) => switch (purpose) {
              OtpPurpose.registration => context.goNamed(AppRoutes.home),
              OtpPurpose.passwordReset => unawaited(_openResetPassword(context)),
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
        builder: (context, state) => UpdateProfilePage(
          initialDraft: const ProfileDraft.defaults(),
          onSave: (_) => _showInformationDialog(
            context,
            title: context.t.common.legalPlaceholderTitle,
            body: context.t.common.notConnected,
          ),
          onAvatarFeedback: () => _showInformationDialog(
            context,
            title: context.t.profile.update.changeAvatar,
            body: context.t.profile.update.avatarUnavailable,
          ),
        ),
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

  // (3a) Session auth-required gate. Composed into the single C5 redirect
  // (no new callback). Reuses AppRoutes.login — NO new route. Behavioral
  // precedence is update -> onboarding -> SESSION -> biometric; the session
  // gate is placed before the onboarding gate but guarded by
  // `hasCompletedOnboarding` so onboarding still wins for fresh installs. An
  // auth-only destination (today: /profile/edit) reached by an anonymous user
  // is sent to /auth/login. Detail routes like /profile/edit are only reachable
  // from the settings shell tab, which onboarding already gates for fresh
  // installs, so the hasCompletedOnboarding guard makes the fresh-install edge
  // unreachable; for returning users the session gate fires correctly.
  if (!_isOnboardingOrAuthRoute(path) && _isAuthRequiredDestination(path)) {
    final hasCompletedOnboarding =
        _readLiveHasCompletedOnboarding(context) ?? hasCompletedOnboardingSeed;
    if (hasCompletedOnboarding) {
      final session = _readLiveSession(context) ?? const AuthAnonymous();
      if (session is! AuthAuthenticated) {
        return AppRoutes.loginPath;
      }
    }
  }

  // (3b) Onboarding gate. Skip when already on an onboarding or auth route —
  // deep links and auth flows must not be hijacked into an onboarding loop.
  if (_isOnboardingOrAuthRoute(path)) {
    return null;
  }
  // Only the shell-tab destinations gate through onboarding. Detail routes
  // (/profile/edit, /dev/*) are reachable from the shell and only render after
  // the shell itself has cleared onboarding, so they do not need to redirect
  // independently.
  if (!_isShellTabDestination(path)) {
    return null;
  }
  // Read LIVE controller state so the in-session Skip -> markOnboardingComplete
  // -> goName(home) path is observable here on the same tick. A captured bool
  // would re-evaluate against the stale pre-mark value and bounce home ->
  // onboarding until relaunch. The seed is a fallback for test harnesses that
  // build the router without a ProviderScope above MaterialApp.router.
  final hasCompleted = _readLiveHasCompletedOnboarding(context) ?? hasCompletedOnboardingSeed;
  if (!hasCompleted) {
    return AppRoutes.onboardingPath;
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

/// Once-per-process guard so the soft-update prompt never nags within a single
/// session (the snooze timestamp covers cross-launch suppression).
bool _softUpdatePromptShown = false;

void _maybeShowSoftUpdateDialog(BuildContext context, UpdateRequirementSoft requirement) {
  if (_softUpdatePromptShown) {
    return;
  }
  final container = ProviderScope.containerOf(context, listen: false);
  final store = container.read(settingsStoreProvider);
  _softUpdatePromptShown = true;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) {
      return;
    }
    unawaited(
      store.readString(SoftUpdateSnooze.key).then((stored) {
        if (!context.mounted || SoftUpdateSnooze.isSnoozed(stored)) {
          return;
        }
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

class _LoginRoutePage extends StatefulWidget {
  const _LoginRoutePage({required this.passwordResetComplete});

  final bool passwordResetComplete;

  @override
  State<_LoginRoutePage> createState() => _LoginRoutePageState();
}

class _LoginRoutePageState extends State<_LoginRoutePage> {
  late bool _passwordResetComplete = widget.passwordResetComplete;

  @override
  void didUpdateWidget(covariant _LoginRoutePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.passwordResetComplete != oldWidget.passwordResetComplete) {
      _passwordResetComplete = widget.passwordResetComplete;
    }
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
      presentation: _passwordResetComplete
          ? LoginPresentationState.success(
              successMessage: context.t.auth.resetPassword.success,
            )
          : const LoginPresentationState(),
      onSubmit: (_) => context.goNamed(AppRoutes.home),
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
