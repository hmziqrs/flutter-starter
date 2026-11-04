import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:starter/features/announcements/announcement_view_data.dart';
import 'package:starter/features/announcements/announcements_controller.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/fx/shaders/brand_material_surface.dart';
import 'package:starter/shared/fx/shaders/brand_materials.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/theme/brand_tokens.dart';
import 'package:starter/shared/widgets/banners/collapsing_banner_slot.dart';
import 'package:starter/shared/widgets/feedback/app_toast.dart';

class AnnouncementBanner extends ConsumerStatefulWidget {
  const AnnouncementBanner({super.key});

  @override
  ConsumerState<AnnouncementBanner> createState() => _AnnouncementBannerState();
}

class _AnnouncementBannerState extends ConsumerState<AnnouncementBanner> {
  @override
  void initState() {
    super.initState();
    ref.listenManual<AnnouncementsState>(
      announcementsControllerProvider,
      (previous, next) {
        if (!mounted) {
          return;
        }
        final becameFailure =
            next.status == AnnouncementsStatus.dismissFailure &&
            previous?.status != AnnouncementsStatus.dismissFailure;
        if (becameFailure) {
          _showDismissFailureToast(context);
          ref.read(announcementsControllerProvider.notifier).acknowledgeFailure();
        }
      },
    );
  }

  void _showDismissFailureToast(BuildContext context) {
    final translations = context.t;
    AppToast.show(
      context,
      severity: ToastSeverity.info,
      message: translations.announcements.dismissFailed,
      icon: FLucideIcons.triangleAlert,
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(
      announcementsControllerProvider.select((state) => state.active),
    );
    return _AnnouncementBannerSlot(
      active: active,
      onDismiss: active == null
          ? null
          : () => ref.read(announcementsControllerProvider.notifier).dismiss(active.id),
      onAction: active == null || active.actionRoute == null
          ? null
          : () => _goAction(context, active.actionRoute!),
    );
  }

  void _goAction(BuildContext context, String route) {
    GoRouter.of(context).goNamed(route);
  }
}

class _AnnouncementBannerSlot extends StatelessWidget {
  const _AnnouncementBannerSlot({required this.active, this.onDismiss, this.onAction});

  final Announcement? active;
  final VoidCallback? onDismiss;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final announcement = active;
    return CollapsingBannerSlot(
      child: announcement == null
          ? null
          : AnnouncementBannerView(
              announcement: announcement,
              onDismiss: onDismiss ?? () {},
              onAction: onAction ?? () {},
            ),
    );
  }
}

class AnnouncementBannerView extends StatelessWidget {
  const AnnouncementBannerView({
    required this.announcement,
    required this.onDismiss,
    required this.onAction,
    super.key,
  });

  final Announcement announcement;
  final VoidCallback onDismiss;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final theme = context.theme;
    final presentation = _presentationFor(announcement.severity, theme.brand, translations);
    final actionRoute = announcement.actionRoute;
    final spacing = context.spacing;
    final fillOpacity = theme.colors.brightness == Brightness.dark ? 0.20 : 0.10;

    // Good news rides the brand's announce bar (announce-bar.svelte): a strip
    // of material holding the words on glass. Warnings and outages stay soft
    // status fills, which are the brand's voice for something going wrong.
    if (announcement.severity == AnnouncementSeverity.info ||
        announcement.severity == AnnouncementSeverity.success) {
      return Semantics(
        container: true,
        liveRegion: true,
        label: '${announcement.title(translations)}. ${announcement.message(translations)}',
        child: _AnnounceBar(
          title: announcement.title(translations),
          message: announcement.message(translations),
          dismissible: announcement.dismissible,
          actionLabel: actionRoute == null ? null : translations.announcements.actionLearnMore,
          dismissLabel: translations.announcements.dismiss,
          onAction: onAction,
          onDismiss: onDismiss,
        ),
      );
    }

    return Semantics(
      container: true,
      liveRegion: true,
      label: '${announcement.title(translations)}. ${announcement.message(translations)}',
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          bottom: false,
          child: Container(
            key: const ValueKey('announcement-banner'),
            width: double.infinity,
            decoration: BoxDecoration(
              // Status is always soft: the role color as a 10% fill (20% in
              // dark), never a solid colored background. The hairline in the
              // role color separates the notice from the page below it. The
              // fill is blended over the theme background so it stays opaque:
              // the banner strip sits above routed content, where nothing
              // paints the page background behind it.
              color: Color.alphaBlend(
                presentation.color.withValues(alpha: fillOpacity),
                theme.colors.background,
              ),
              border: Border(
                bottom: BorderSide(color: presentation.color.withValues(alpha: 0.4)),
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: spacing.lg, vertical: spacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: 1),
                  child: Icon(
                    presentation.icon,
                    size: 18,
                    color: presentation.color,
                    semanticLabel: presentation.label,
                  ),
                ),
                SizedBox(width: spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        announcement.title(translations),
                        style: theme.typography.body.sm.copyWith(
                          color: theme.colors.foreground,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: spacing.xs),
                      Text(
                        announcement.message(translations),
                        style: theme.typography.body.sm.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: spacing.md),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (actionRoute != null) ...[
                      FButton(
                        key: const ValueKey('announcement-action'),
                        variant: .outline,
                        size: .sm,
                        style: _quietPressStyle,
                        onPress: onAction,
                        child: Text(translations.announcements.actionLearnMore),
                      ),
                      SizedBox(width: spacing.sm),
                    ],
                    if (announcement.dismissible)
                      FButton.icon(
                        key: const ValueKey('announcement-dismiss'),
                        variant: .ghost,
                        size: .sm,
                        style: _quietPressStyle,
                        semanticsLabel: translations.announcements.dismiss,
                        onPress: onDismiss,
                        child: const Icon(FLucideIcons.x, size: 16),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Brand motion rule: press feedback is color only, so the stock bounce
  /// (a 0.97 press scale) is switched off on the banner's controls.
  static const FButtonStyleDelta _quietPressStyle = FButtonStyleDelta.delta(
    tappableStyle: FTappableStyleDelta.delta(motion: FTappableMotion.none),
  );
}

class _AnnounceBar extends StatelessWidget {
  const _AnnounceBar({
    required this.title,
    required this.message,
    required this.dismissible,
    required this.dismissLabel,
    required this.onAction,
    required this.onDismiss,
    this.actionLabel,
  });

  final String title;
  final String message;
  final bool dismissible;
  final String? actionLabel;
  final String dismissLabel;
  final VoidCallback onAction;
  final VoidCallback onDismiss;

  /// The pill's bar width, past which it stops growing and centers.
  static const double _maxWidth = 760;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final spacing = context.spacing;
    final titleStyle = theme.typography.body.sm.copyWith(
      color: theme.colors.foreground,
      fontWeight: FontWeight.w500,
    );
    final messageStyle = theme.typography.body.sm.copyWith(color: theme.colors.mutedForeground);
    final titleText = Text(title, style: titleStyle, maxLines: 2, overflow: TextOverflow.ellipsis);
    final messageText = Text(
      message,
      style: messageStyle,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );

    return Stack(
      key: const ValueKey('announcement-banner'),
      children: [
        Positioned.fill(
          // A still frame, as the kit renders this bar: an always-on strip
          // should not spend frames on ambient motion.
          child: Builder(
            builder: (context) {
              final recipe = brandMaterialById('copper-sweep')!;
              return BrandMaterialSurface(recipe: recipe, time: recipe.time);
            },
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: spacing.lg, vertical: spacing.sm),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxWidth),
                // The words never sit on the material itself (BRAND.md s13):
                // the page color is nearly opaque under them.
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: theme.colors.background.withValues(alpha: 0.92),
                    shape: RoundedSuperellipseBorder(
                      borderRadius: theme.style.borderRadius.lg,
                      side: BorderSide(color: theme.colors.border),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                      spacing.md,
                      spacing.xs,
                      spacing.xs,
                      spacing.xs,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) => constraints.maxWidth >= 560
                                ? Row(
                                    children: [
                                      Flexible(child: titleText),
                                      SizedBox(width: spacing.md),
                                      Expanded(child: messageText),
                                    ],
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [titleText, messageText],
                                  ),
                          ),
                        ),
                        if (actionLabel != null) ...[
                          SizedBox(width: spacing.sm),
                          FButton(
                            key: const ValueKey('announcement-action'),
                            variant: .outline,
                            size: .sm,
                            style: AnnouncementBannerView._quietPressStyle,
                            onPress: onAction,
                            child: Text(actionLabel!),
                          ),
                        ],
                        if (dismissible) ...[
                          SizedBox(width: spacing.xs),
                          FButton.icon(
                            key: const ValueKey('announcement-dismiss'),
                            variant: .ghost,
                            size: .sm,
                            style: AnnouncementBannerView._quietPressStyle,
                            semanticsLabel: dismissLabel,
                            onPress: onDismiss,
                            child: const Icon(FLucideIcons.x, size: 16),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

({Color color, IconData icon, String label}) _presentationFor(
  AnnouncementSeverity severity,
  AppBrandColors brand,
  Translations translations,
) {
  return switch (severity) {
    AnnouncementSeverity.info => (
      color: brand.info,
      icon: FLucideIcons.info,
      label: translations.announcements.severityInfo,
    ),
    AnnouncementSeverity.success => (
      color: brand.success,
      icon: FLucideIcons.circleCheck,
      label: translations.announcements.severitySuccess,
    ),
    AnnouncementSeverity.warning => (
      color: brand.warning,
      icon: FLucideIcons.triangleAlert,
      label: translations.announcements.severityWarning,
    ),
    AnnouncementSeverity.critical => (
      color: brand.destructive,
      icon: FLucideIcons.octagonAlert,
      label: translations.announcements.severityCritical,
    ),
  };
}
