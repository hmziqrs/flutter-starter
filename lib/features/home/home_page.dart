import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/home/home_controller.dart';
import 'package:starter/features/home/home_view_data.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/adaptive/app_layout_class.dart';
import 'package:starter/shared/adaptive/app_layout_provider.dart';
import 'package:starter/shared/theme/app_presentation_tokens.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/feedback/app_toast.dart';
import 'package:starter/shared/widgets/lists/data_list_view.dart';
import 'package:starter/shared/widgets/reading_content_scroll_frame.dart';
import 'package:starter/shared/widgets/refresh/app_refresh_indicator.dart';
import 'package:starter/shared/widgets/spaced_column.dart';
import 'package:starter/shared/widgets/states/empty_state_view.dart';
import 'package:starter/shared/widgets/states/error_state_view.dart';
import 'package:starter/shared/widgets/states/skeleton_tile.dart';
import 'package:starter/shared/widgets/states/skeleton_view.dart';

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
    final spacing = context.spacing;
    final tokens = context.presentationTokens;

    return SafeArea(
      bottom: false,
      child: AppRefreshIndicator(
        onRefresh: () => _refreshRecentActivity(context, ref),
        child: ReadingContentScrollFrame(
          key: ValueKey('home-layout-${layoutClass.name}'),
          maxWidth: tokens.wideContentMaxWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HomeHeader(viewData: viewData),
              SizedBox(height: spacing.xl),
              _QuickActions(
                columns: layoutClass == AppLayoutClass.compact ? 1 : 2,
                onOpenProfile: onOpenProfile,
                onOpenPricing: onOpenPricing,
                onOpenSettings: onOpenSettings,
                onOpenLogin: onOpenLogin,
              ),
              SizedBox(height: spacing.xl),
              _StatusSection(viewData: viewData, columns: columns),
              SizedBox(height: spacing.xl),
              const _RecentActivity(),
            ],
          ),
        ),
      ),
    );
  }

  /// Backend-free by contract (`pull-refresh.md`): recompose the local feed,
  /// then report the honest `common.notConnected` outcome — never faked success.
  Future<void> _refreshRecentActivity(BuildContext context, WidgetRef ref) async {
    ref.invalidate(homeRecentActivityProvider);
    await ref.read(homeRecentActivityProvider.future);
    if (!context.mounted) return;
    AppToast.show(
      context,
      severity: ToastSeverity.warning,
      message: context.t.common.notConnected,
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
        SizedBox(height: context.spacing.sm),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(translations.quickActions, style: context.theme.typography.display.lg),
        SizedBox(height: context.spacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            final spacing = context.spacing;
            final tokens = context.presentationTokens;
            final minimumCardExtent = tokens.focusTargetMinSize * 4;
            final resolvedColumns = constraints.maxWidth >= (minimumCardExtent * 2) + spacing.md
                ? math.min(columns, 2)
                : 1;
            final tileWidth =
                (constraints.maxWidth - spacing.md * (resolvedColumns - 1)) / resolvedColumns;
            return FocusTraversalGroup(
              policy: ReadingOrderTraversalPolicy(),
              child: Wrap(
                key: ValueKey('home-quick-actions-$resolvedColumns'),
                spacing: spacing.md,
                runSpacing: spacing.md,
                children: [
                  SizedBox(
                    width: tileWidth,
                    child: _QuickAction(
                      buttonKey: const ValueKey('home-open-profile'),
                      icon: FLucideIcons.userRound,
                      label: translations.editProfile,
                      onPress: onOpenProfile,
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: _QuickAction(
                      buttonKey: const ValueKey('home-open-pricing'),
                      icon: FLucideIcons.creditCard,
                      label: translations.openPricing,
                      onPress: onOpenPricing,
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: _QuickAction(
                      buttonKey: const ValueKey('home-open-settings'),
                      icon: FLucideIcons.settings,
                      label: translations.openSettings,
                      onPress: onOpenSettings,
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: _QuickAction(
                      buttonKey: const ValueKey('home-open-login'),
                      icon: FLucideIcons.logIn,
                      label: translations.openLogin,
                      onPress: onOpenLogin,
                    ),
                  ),
                ],
              ),
            );
          },
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
        SizedBox(height: context.spacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            final spacing = context.spacing;
            final gaps = spacing.sm * (columns - 1);
            final cardWidth = (constraints.maxWidth - gaps) / columns;
            return Wrap(
              key: ValueKey('home-status-grid-$columns'),
              spacing: spacing.sm,
              runSpacing: spacing.sm,
              children: [
                for (final status in viewData.statuses)
                  SizedBox(
                    width: cardWidth,
                    child: _StatusCard(status: status),
                  ),
              ],
            );
          },
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
    final spacing = context.spacing;
    return FCard(
      key: ValueKey('home-status-${status.id}'),
      child: Padding(
        padding: EdgeInsets.all(spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(content.icon),
            SizedBox(height: spacing.md),
            Text(content.title, style: context.theme.typography.display.md),
            SizedBox(height: spacing.sm),
            Text(content.body, style: context.theme.typography.body.sm),
          ],
        ),
      ),
    );
  }
}

class _RecentActivity extends ConsumerWidget {
  const _RecentActivity();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translations = context.t.home;
    final feed = ref.watch(homeRecentActivityProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(translations.recentTitle, style: context.theme.typography.display.lg),
        SizedBox(height: context.spacing.sm),
        switch (feed) {
          AsyncData(:final value) =>
            value.isEmpty
                ? EmptyStateView(
                    key: const ValueKey('home-activity-empty'),
                    title: translations.recentEmptyTitle,
                    body: translations.recentEmptyBody,
                  )
                : DataListView<HomeActivityViewData>(
                    key: const ValueKey('home-activity-list'),
                    items: value,
                    itemBuilder: (context, activity) => _ActivityTile(activity: activity),
                    keyOf: (activity) => activity.id,
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    separator: SizedBox(height: context.spacing.sm),
                  ),
          AsyncError() => ErrorStateView(
            key: const ValueKey('home-activity-error'),
            title: context.t.states.errorTitle,
            body: context.t.states.errorBody,
          ),
          // Feed composes after the first frame; bones mirror incoming tiles.
          AsyncLoading() => SkeletonView(
            key: const ValueKey('home-activity-skeleton'),
            child: SpacedColumn(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < HomeViewData.defaultActivity.length; index++)
                  SizedBox(
                    key: ValueKey('home-activity-skeleton-$index'),
                    child: const SkeletonTile(),
                  ),
              ],
            ),
          ),
        },
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
