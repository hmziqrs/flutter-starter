import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/home/home_view_data.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/adaptive/app_layout_class.dart';
import 'package:starter/shared/adaptive/app_layout_provider.dart';
import 'package:starter/shared/adaptive/app_unit.dart';
import 'package:starter/shared/theme/app_sizes.dart';
import 'package:starter/shared/theme/app_spacing.dart';

class HomePage extends ConsumerWidget {
  const HomePage({
    required this.viewData,
    required this.onOpenProfile,
    required this.onOpenPricing,
    required this.onOpenSettings,
    required this.onOpenLogin,
    super.key,
  });

  final HomeViewData viewData;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenPricing;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenLogin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layoutClass = ref.watch(appLayoutClassProvider);
    final columns = switch (layoutClass) {
      AppLayoutClass.compact => 1,
      AppLayoutClass.medium => 2,
      AppLayoutClass.expanded => 3,
    };

    return ListView(
      key: ValueKey('home-layout-${layoutClass.name}'),
      padding: EdgeInsetsDirectional.fromSTEB(
        context.spacing.xl,
        context.spacing.xl2,
        context.spacing.xl,
        context.spacing.xl3 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSizes.wideContentMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HomeHeader(viewData: viewData),
                SizedBox(height: context.spacing.xl2),
                _QuickActions(
                  columns: layoutClass == AppLayoutClass.compact ? 1 : 2,
                  onOpenProfile: onOpenProfile,
                  onOpenPricing: onOpenPricing,
                  onOpenSettings: onOpenSettings,
                  onOpenLogin: onOpenLogin,
                ),
                SizedBox(height: context.spacing.xl2),
                _StatusSection(viewData: viewData, columns: columns),
                SizedBox(height: context.spacing.xl2),
                _RecentActivity(viewData: viewData),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.viewData});

  final HomeViewData viewData;

  @override
  Widget build(BuildContext context) {
    final translations = context.t.home;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          translations.greeting(name: viewData.greetingName),
          key: const ValueKey('home-greeting'),
          style: context.theme.typography.display.xl3,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(translations.summary, style: context.theme.typography.body.lg),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.columns,
    required this.onOpenProfile,
    required this.onOpenPricing,
    required this.onOpenSettings,
    required this.onOpenLogin,
  });

  final int columns;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenPricing;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenLogin;

  @override
  Widget build(BuildContext context) {
    final translations = context.t.home;
    final minimumButtonHeight =
        context.theme.buttonStyles.primary.md.contentStyle.constraints.minHeight;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(translations.quickActions, style: context.theme.typography.display.lg),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          key: ValueKey('home-quick-actions-$columns'),
          crossAxisCount: columns,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          mainAxisExtent: math.max(
            minimumButtonHeight,
            context.appUnit.un(minimumButtonHeight),
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _QuickAction(
              buttonKey: const ValueKey('home-open-profile'),
              icon: FLucideIcons.userRound,
              label: translations.editProfile,
              onPress: onOpenProfile,
            ),
            _QuickAction(
              buttonKey: const ValueKey('home-open-pricing'),
              icon: FLucideIcons.creditCard,
              label: translations.openPricing,
              onPress: onOpenPricing,
            ),
            _QuickAction(
              buttonKey: const ValueKey('home-open-settings'),
              icon: FLucideIcons.settings,
              label: translations.openSettings,
              onPress: onOpenSettings,
            ),
            _QuickAction(
              buttonKey: const ValueKey('home-open-login'),
              icon: FLucideIcons.logIn,
              label: translations.openLogin,
              onPress: onOpenLogin,
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.buttonKey,
    required this.icon,
    required this.label,
    required this.onPress,
  });

  final Key buttonKey;
  final IconData icon;
  final String label;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    return FButton(
      key: buttonKey,
      variant: .outline,
      mainAxisAlignment: MainAxisAlignment.start,
      prefix: Icon(icon),
      builder: (_, _, _, _, _, child) => Flexible(child: child!),
      onPress: onPress,
      child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis),
    );
  }
}

class _StatusSection extends StatelessWidget {
  const _StatusSection({required this.viewData, required this.columns});

  final HomeViewData viewData;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.t.home.statusTitle, style: context.theme.typography.display.lg),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          key: ValueKey('home-status-grid-$columns'),
          crossAxisCount: columns,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: (columns == 1 ? 2.4 : 1.4) / context.appUnit.typographyScale,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [for (final status in viewData.statuses) _StatusCard(status: status)],
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.status});

  final HomeStatusViewData status;

  @override
  Widget build(BuildContext context) {
    final content = _statusContent(context.t, status.kind);
    return FCard(
      key: ValueKey('home-status-${status.id}'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(content.icon),
            const SizedBox(height: AppSpacing.md),
            Text(content.title, style: context.theme.typography.display.md),
            const SizedBox(height: AppSpacing.sm),
            Flexible(child: Text(content.body, style: context.theme.typography.body.sm)),
          ],
        ),
      ),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity({required this.viewData});

  final HomeViewData viewData;

  @override
  Widget build(BuildContext context) {
    final translations = context.t.home;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(translations.recentTitle, style: context.theme.typography.display.lg),
        const SizedBox(height: AppSpacing.md),
        if (!viewData.hasRecentActivity)
          FCard(
            key: const ValueKey('home-activity-empty'),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    translations.recentEmptyTitle,
                    style: context.theme.typography.display.md,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(translations.recentEmptyBody),
                ],
              ),
            ),
          )
        else
          FCard(
            key: const ValueKey('home-activity-list'),
            child: Column(
              children: [
                for (final activity in viewData.recentActivity) _ActivityTile(activity: activity),
              ],
            ),
          ),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity});

  final HomeActivityViewData activity;

  @override
  Widget build(BuildContext context) {
    final content = _statusContent(context.t, activity.kind);
    return FTile(
      key: ValueKey('home-activity-${activity.id}'),
      prefix: Icon(content.icon),
      title: Text(content.title),
      subtitle: Text(content.body),
    );
  }
}

({IconData icon, String title, String body}) _statusContent(
  Translations translations,
  HomeStatusKind kind,
) {
  return switch (kind) {
    HomeStatusKind.ready => (
      icon: FLucideIcons.circleCheck,
      title: translations.home.statusReadyTitle,
      body: translations.home.statusReadyBody,
    ),
    HomeStatusKind.adaptive => (
      icon: FLucideIcons.panelsTopLeft,
      title: translations.home.statusAdaptiveTitle,
      body: translations.home.statusAdaptiveBody,
    ),
    HomeStatusKind.localized => (
      icon: FLucideIcons.languages,
      title: translations.home.statusLocalizedTitle,
      body: translations.home.statusLocalizedBody,
    ),
  };
}
