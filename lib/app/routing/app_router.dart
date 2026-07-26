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
import 'package:starter/features/home/home_page.dart';
import 'package:starter/features/home/home_view_data.dart';
import 'package:starter/features/onboarding/onboarding_page.dart';
import 'package:starter/features/pricing/paywall_page.dart';
import 'package:starter/features/pricing/plan_view_data.dart';
import 'package:starter/features/pricing/pricing_page.dart';
import 'package:starter/features/profile/profile_view_data.dart';
import 'package:starter/features/profile/update_profile_page.dart';
import 'package:starter/features/settings/settings_page.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';
import 'package:starter/shared/adaptive/app_layout_class.dart';
import 'package:starter/shared/adaptive/app_layout_provider.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/escape_dismissible_overlay.dart';

GoRouter buildAppRouter({
  required AppConfig config,
  String initialLocation = AppRoutes.homePath,
}) {
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
        name: AppRoutes.onboarding,
        path: AppRoutes.onboardingPath,
        builder: (context, state) => OnboardingPage(
          onSkip: () => context.goNamed(AppRoutes.home),
          onOpenPaywall: () => context.goNamed(AppRoutes.onboardingPaywall),
        ),
      ),
      GoRoute(
        name: AppRoutes.onboardingPaywall,
        path: AppRoutes.onboardingPaywallPath,
        builder: (context, state) => PaywallPage(
          plans: PricingFixtures.standard(context.t),
          onSkip: () => context.goNamed(AppRoutes.home),
          onContinue: (_, _) => context.goNamed(AppRoutes.home),
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
        name: AppRoutes.login,
        path: AppRoutes.loginPath,
        builder: (context, state) => LoginPage(
          presentation: state.uri.queryParameters['status'] == _passwordResetComplete
              ? LoginPresentationState.success(
                  successMessage: context.t.auth.resetPassword.success,
                )
              : const LoginPresentationState(),
          onSubmit: (_) => context.goNamed(AppRoutes.home),
          onForgotPassword: () => context.pushNamed(AppRoutes.forgotPassword),
          onRegister: () => context.pushNamed(AppRoutes.register),
        ),
      ),
      GoRoute(
        name: AppRoutes.register,
        path: AppRoutes.registerPath,
        builder: (context, state) => RegisterPage(
          onSubmit: (_) => context.go(
            AppRoutes.otpLocation(OtpPurpose.registration),
          ),
          onLogin: () => context.goNamed(AppRoutes.login),
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
          onSubmit: (_) => context.go(
            AppRoutes.otpLocation(OtpPurpose.passwordReset),
          ),
          onLogin: () => context.goNamed(AppRoutes.login),
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
              OtpPurpose.passwordReset => context.goNamed(AppRoutes.resetPassword),
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
          onSubmit: (_) => context.goNamed(
            AppRoutes.login,
            queryParameters: {'status': _passwordResetComplete},
          ),
          onLogin: () => context.goNamed(AppRoutes.login),
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
    redirect: _redirectSettingsDeepLinks,
  );
}

// Normalizes dedicated settings detail deep links (/settings/appearance,
// /settings/language) to the /settings?section=… query form. A cold-start
// deep-link to a dedicated path would otherwise leave the settings branch
// holding a page keyed ValueKey("/settings/appearance"); a subsequent wide
// section switch (replaceNamed to /settings?section=…) changes the matched
// path/key and fires the platform page transition the migration exists to
// remove. Normalizing on entry keeps the page key ValueKey("/settings") for
// all settings pages on medium/expanded, so wide section switches run no
// transition. Content is unchanged: SettingsPage reads ?section=, so the
// appearance/language content still renders.
String? _redirectSettingsDeepLinks(BuildContext context, GoRouterState state) {
  final path = state.uri.path;
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
  return null;
}

const _passwordResetComplete = 'password-reset-complete';

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
