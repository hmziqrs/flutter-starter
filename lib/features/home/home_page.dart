import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/home/home_controller.dart';
import 'package:starter/features/home/home_view_data.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/adaptive/app_layout_class.dart';
import 'package:starter/shared/adaptive/app_layout_provider.dart';
import 'package:starter/shared/theme/app_presentation_tokens.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/blocks/page_intro.dart';
import 'package:starter/shared/widgets/blocks/section_block.dart';
import 'package:starter/shared/widgets/brand/app_icon_tile.dart';
import 'package:starter/shared/widgets/brand/app_ring_marker.dart';
import 'package:starter/shared/widgets/brand/app_status_tag.dart';
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
    this.feedLoader,
    super.key,
  });

  final HomeViewData viewData;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenPricing;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenLogin;

  /// Per-instance feed source for deterministic previews (dev gallery).
  ///
  /// Production leaves this null so the backend-free `homeRecentActivityProvider`
  /// composes the feed; previews pass the case's `recentActivity` so the mounted
  /// state matches the gallery case instead of the provider's default list.
  final Future<List<HomeActivityViewData>> Function()? feedLoader;

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
    final previewFeedLoader = feedLoader;

    final body = SafeArea(
      bottom: false,
      child: AppRefreshIndicator(
        onRefresh: () => _refreshRecentActivity(context, ref),
        child: ReadingContentScrollFrame(
          key: ValueKey('home-layout-${layoutClass.name}'),
          maxWidth: tokens.wideContentMaxWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Page intro pattern (APP-BLOCKS app type scale): the greeting is
              // the 24 w500 tight page title, the summary its one muted line.
              AppPageIntro(
                key: const ValueKey('home-greeting'),
                title: context.t.home.greeting(name: viewData.greetingName),
                description: context.t.home.summary,
              ),
              SizedBox(height: spacing.xl),
              AppSectionBlock(
                title: context.t.home.quickActions,
                child: _QuickActions(
                  columns: layoutClass == AppLayoutClass.compact ? 1 : 2,
                  onOpenProfile: onOpenProfile,
                  onOpenPricing: onOpenPricing,
                  onOpenSettings: onOpenSettings,
                  onOpenLogin: onOpenLogin,
                ),
              ),
              SizedBox(height: spacing.xl),
              AppSectionBlock(
                title: context.t.home.statusTitle,
                child: _StatusSection(viewData: viewData, columns: columns),
              ),
              SizedBox(height: spacing.xl),
              AppSectionBlock(title: context.t.home.recentTitle, child: const _RecentActivity()),
            ],
          ),
        ),
      ),
    );

    if (previewFeedLoader == null) {
      return body;
    }
    // Same nested-scope pattern as `AppLayoutScope`: previews scope the feed to
    // this page instance so the rendered state tracks the case's view data.
    return ProviderScope(
      overrides: [
        homeRecentActivityProvider.overrideWith((ref) => previewFeedLoader()),
      ],
      child: body,
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
    return LayoutBuilder(
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
                child: _QuickActionCard(
                  actionKey: const ValueKey('home-open-profile'),
                  icon: FLucideIcons.userRound,
                  label: translations.editProfile,
                  description: translations.editProfileHint,
                  onPress: onOpenProfile,
                ),
              ),
              SizedBox(
                width: tileWidth,
                child: _QuickActionCard(
                  actionKey: const ValueKey('home-open-pricing'),
                  icon: FLucideIcons.creditCard,
                  label: translations.openPricing,
                  description: translations.openPricingHint,
                  onPress: onOpenPricing,
                ),
              ),
              SizedBox(
                width: tileWidth,
                child: _QuickActionCard(
                  actionKey: const ValueKey('home-open-settings'),
                  icon: FLucideIcons.settings,
                  label: translations.openSettings,
                  description: translations.openSettingsHint,
                  onPress: onOpenSettings,
                ),
              ),
              SizedBox(
                width: tileWidth,
                child: _QuickActionCard(
                  actionKey: const ValueKey('home-open-login'),
                  icon: FLucideIcons.logIn,
                  label: translations.openLogin,
                  description: translations.openLoginHint,
                  onPress: onOpenLogin,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// One quick action as the brand's outline tile card (BRAND.md s8/s9): a thin
/// line and no fill at rest, the 36px outline icon tile, the 14 w500 label,
/// and one muted 14 line saying what the action does (APP-BLOCKS feature-grid
/// item, scaled to a cell).
///
/// Hover, press and focus are color-only — the border takes the oxide accent
/// at half strength (BRAND.md s4) and keyboard focus draws the theme's oxide
/// outline. Nothing scales, moves or fills.
class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.actionKey,
    required this.icon,
    required this.label,
    required this.description,
    required this.onPress,
  });

  final Key actionKey;
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final spacing = context.spacing;
    return FTappable.static(
      key: actionKey,
      focusedOutlineStyle: const FFocusedOutlineStyleDelta.context(),
      onPress: onPress,
      builder: (context, variants, child) {
        final active =
            variants.contains(FTappableVariant.hovered) ||
            variants.contains(FTappableVariant.pressed);
        final border = active ? theme.colors.primary.withValues(alpha: 0.5) : theme.colors.border;
        return DecoratedBox(
          decoration: ShapeDecoration(
            color: Colors.transparent,
            shape: RoundedSuperellipseBorder(
              side: BorderSide(color: border, width: theme.style.borderWidth),
              borderRadius: theme.style.borderRadius.lg,
            ),
          ),
          child: child,
        );
      },
      child: Padding(
        padding: EdgeInsets.all(spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIconTile(icon: icon),
            SizedBox(height: spacing.md),
            // App type scale (APP-BLOCKS): cells and labels run 14, at w500.
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.typography.body.sm.copyWith(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: spacing.xs),
            // Descriptions run 14 muted (APP-BLOCKS).
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.typography.body.sm.copyWith(color: theme.colors.mutedForeground),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusSection extends StatelessWidget {
  const _StatusSection({required this.viewData, required this.columns});

  final HomeViewData viewData;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Columns come from the layout class, but a column is only real if a
        // whole pill fits inside it. The floor is the widest status pill
        // measured with the tag's own recipe at the active type scale, so a
        // label never clips or ellipsizes: under large type or wide scripts
        // (and in test metrics) the grid quietly drops columns instead.
        final pillFloor = _widestPillWidth(context);
        var resolvedColumns = columns;
        while (resolvedColumns > 1 &&
            (constraints.maxWidth - spacing.sm * (resolvedColumns - 1)) / resolvedColumns <
                pillFloor) {
          resolvedColumns -= 1;
        }
        final gaps = spacing.sm * (resolvedColumns - 1);
        final cellWidth = (constraints.maxWidth - gaps) / resolvedColumns;
        return Wrap(
          key: ValueKey('home-status-grid-$resolvedColumns'),
          spacing: spacing.sm,
          runSpacing: spacing.sm,
          children: [
            for (final status in viewData.statuses)
              SizedBox(
                width: cellWidth,
                child: _StatusItem(status: status),
              ),
          ],
        );
      },
    );
  }

  /// The widest [AppStatusTag] this section renders, measured with the tag's
  /// recipe: the label at body.xs w500, the live 7px marker and its 6px gap,
  /// and the tag's 16px horizontal padding. Measuring (rather than guessing)
  /// keeps the floor true for every font scale, locale and test font.
  double _widestPillWidth(BuildContext context) {
    final theme = context.theme;
    final style = theme.typography.body.xs.copyWith(fontWeight: FontWeight.w500);
    final textDirection = Directionality.of(context);
    final textScaler = MediaQuery.textScalerOf(context);
    var widest = 0.0;
    for (final status in viewData.statuses) {
      final painter = TextPainter(
        text: TextSpan(text: _statusContent(context.t, status.kind).title, style: style),
        textDirection: textDirection,
        textScaler: textScaler,
      )..layout();
      final marker = status.kind == HomeStatusKind.ready ? 7.0 + 6 : 0.0;
      final width = painter.width + marker + AppSpacing.sm * 2;
      painter.dispose();
      if (width > widest) {
        widest = width;
      }
    }
    return widest;
  }
}

/// One foundation status, soft and quiet (BRAND.md s4, s8): the title rides a
/// soft `AppStatusTag` pill in its role color — never a solid fill, never a
/// display card — with the live state carrying the hollow ring marker, and the
/// detail line muted at 14 under it.
class _StatusItem extends StatelessWidget {
  const _StatusItem({required this.status});

  final HomeStatusViewData status;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final spacing = context.spacing;
    final content = _statusContent(context.t, status.kind);
    return Column(
      key: ValueKey('home-status-${status.id}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppStatusTag(
          label: content.title,
          role: switch (status.kind) {
            // Green means ready and live; the marker says so without color.
            HomeStatusKind.ready => AppStatusRole.success,
            // Blue means information: the adaptive and localized facts.
            HomeStatusKind.adaptive || HomeStatusKind.localized => AppStatusRole.info,
          },
          showMarker: status.kind == HomeStatusKind.ready,
        ),
        SizedBox(height: spacing.sm),
        // Descriptions run 14 muted (APP-BLOCKS).
        Text(
          content.body,
          style: theme.typography.body.sm.copyWith(color: theme.colors.mutedForeground),
        ),
      ],
    );
  }
}

class _RecentActivity extends ConsumerWidget {
  const _RecentActivity();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translations = context.t.home;
    final feed = ref.watch(homeRecentActivityProvider);
    return SizedBox(
      width: double.infinity,
      child: switch (feed) {
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
    );
  }
}

/// One recent-activity entry as the brand's quiet list row (BRAND.md s7/s8):
/// a ring-marker bullet beside the words — filled when the thing is done —
/// and the detail line muted at 14. No card, no icon, no color for color's
/// sake; the feed's view data carries no timestamps, so the muted line is the
/// entry's own detail sentence rather than an invented time.
class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity});

  final HomeActivityViewData activity;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final spacing = context.spacing;
    final content = _statusContent(context.t, activity.kind);
    final titleStyle = theme.typography.body.sm;
    final marker = AppRingMarker(
      // Filled means done (BRAND.md s7): the ready entry has landed.
      filled: activity.kind == HomeStatusKind.ready,
    );
    // Center the marker on the title's first line, derived from the type
    // token so it stays true at every font scale.
    final firstLineExtent = (titleStyle.height ?? 1) * (titleStyle.fontSize ?? 14);
    return Row(
      key: ValueKey('home-activity-${activity.id}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: (firstLineExtent - marker.size) / 2),
          child: marker,
        ),
        SizedBox(width: spacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(content.title, style: titleStyle),
              SizedBox(height: spacing.xs),
              Text(
                content.body,
                style: theme.typography.body.sm.copyWith(color: theme.colors.mutedForeground),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

({String title, String body}) _statusContent(Translations translations, HomeStatusKind kind) {
  return switch (kind) {
    HomeStatusKind.ready => (
      title: translations.home.statusReadyTitle,
      body: translations.home.statusReadyBody,
    ),
    HomeStatusKind.adaptive => (
      title: translations.home.statusAdaptiveTitle,
      body: translations.home.statusAdaptiveBody,
    ),
    HomeStatusKind.localized => (
      title: translations.home.statusLocalizedTitle,
      body: translations.home.statusLocalizedBody,
    ),
  };
}
