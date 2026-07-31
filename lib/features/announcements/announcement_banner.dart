import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:starter/features/announcements/announcement_view_data.dart';
import 'package:starter/features/announcements/announcements_controller.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/motion/app_motion.dart';
import 'package:starter/shared/theme/app_spacing.dart';

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
    showFToast(
      context: context,
      icon: Icon(
        FLucideIcons.triangleAlert,
        size: 18,
        color: context.theme.colors.primary,
        semanticLabel: translations.announcements.dismissFailed,
      ),
      title: Text(translations.announcements.dismissFailed),
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(announcementsControllerProvider).active;
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
    final content = announcement == null
        ? const SizedBox(width: double.infinity, height: 0)
        : AnnouncementBannerView(
            announcement: announcement,
            onDismiss: onDismiss ?? () {},
            onAction: onAction ?? () {},
          );

    if (MediaQuery.disableAnimationsOf(context)) {
      return content;
    }
    return AnimatedSize(
      duration: AppMotion.standard,
      curve: AppMotion.standardCurve,
      alignment: Alignment.topCenter,
      child: content,
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
    final presentation = _presentationFor(announcement.severity, translations);
    final actionRoute = announcement.actionRoute;

    return Semantics(
      container: true,
      liveRegion: true,
      label: '${announcement.title(translations)}. ${announcement.message(translations)}',
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: SizedBox(
              width: double.infinity,
              child: FAlert(
                variant: presentation.variant,
                icon: Icon(
                  presentation.icon,
                  size: 18,
                  semanticLabel: presentation.severityLabel,
                ),
                title: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        announcement.title(translations),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (actionRoute != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      FButton(
                        variant: .outline,
                        size: .sm,
                        onPress: onAction,
                        child: Text(translations.announcements.actionLearnMore),
                      ),
                    ],
                    if (announcement.dismissible) ...[
                      const SizedBox(width: AppSpacing.sm),
                      FButton.icon(
                        variant: .ghost,
                        size: .sm,
                        semanticsLabel: translations.announcements.dismiss,
                        onPress: onDismiss,
                        child: const Icon(FLucideIcons.x, size: 16),
                      ),
                    ],
                  ],
                ),
                subtitle: Text(
                  announcement.message(translations),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

({FAlertVariant variant, IconData icon, String severityLabel}) _presentationFor(
  AnnouncementSeverity severity,
  Translations translations,
) {
  return switch (severity) {
    AnnouncementSeverity.info => (
      variant: FAlertVariant.primary,
      icon: FLucideIcons.info,
      severityLabel: translations.announcements.severityInfo,
    ),
    AnnouncementSeverity.success => (
      variant: FAlertVariant.primary,
      icon: FLucideIcons.circleCheck,
      severityLabel: translations.announcements.severitySuccess,
    ),
    AnnouncementSeverity.warning => (
      variant: FAlertVariant.destructive,
      icon: FLucideIcons.triangleAlert,
      severityLabel: translations.announcements.severityWarning,
    ),
    AnnouncementSeverity.critical => (
      variant: FAlertVariant.destructive,
      icon: FLucideIcons.octagonAlert,
      severityLabel: translations.announcements.severityCritical,
    ),
  };
}
