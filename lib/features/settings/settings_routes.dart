import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/app/routing/route_support.dart';
import 'package:starter/features/settings/license_page.dart';
import 'package:starter/features/settings/settings_page.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';
import 'package:starter/shared/adaptive/app_layout_class.dart';
import 'package:starter/shared/adaptive/app_layout_provider.dart';

List<RouteBase> buildSettingsRoutes() => [
  GoRoute(
    name: AppRoutes.settings,
    path: AppRoutes.settingsPath,
    builder: (context, state) => buildSettingsPage(
      context,
      SettingsSection.tryParse(state.uri.queryParameters['section']),
    ),
  ),
  GoRoute(
    name: AppRoutes.appearanceSettings,
    path: AppRoutes.appearanceSettingsPath,
    builder: (context, state) => buildSettingsPage(context, SettingsSection.appearance),
  ),
  GoRoute(
    name: AppRoutes.languageSettings,
    path: AppRoutes.languageSettingsPath,
    builder: (context, state) => buildSettingsPage(context, SettingsSection.language),
  ),
  GoRoute(
    name: AppRoutes.accessibilitySettings,
    path: AppRoutes.accessibilitySettingsPath,
    builder: (context, state) => buildSettingsPage(context, SettingsSection.accessibility),
  ),
  GoRoute(
    name: AppRoutes.aboutLicense,
    path: AppRoutes.aboutLicensePath,
    builder: (context, state) => const AboutLicensePage(),
  ),
];

SettingsPage buildSettingsPage(BuildContext context, SettingsSection? section) {
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
    onOpenPricing: () => goAppTab(context, 1),
    onOpenPasscodeSetup: () => unawaited(context.pushNamed<void>(AppRoutes.passcodeSetup)),
    onOpenTerms: () => showAppInformationDialog(
      context,
      title: context.t.settings.terms,
    ),
    onOpenPrivacy: () => showAppInformationDialog(
      context,
      title: context.t.settings.privacy,
    ),
    onOpenLicense: () => context.pushNamed(AppRoutes.aboutLicense),
    loadBuildLabel: () async => (await AppBuildInfo.load()).displayValue,
  );
}

void _openSettingsSection(BuildContext context, SettingsSection section) {
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
