import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:starter/features/announcements/announcement_view_data.dart';
import 'package:starter/features/announcements/announcements_controller.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/motion/app_motion.dart';
import 'package:starter/shared/theme/app_spacing.dart';

/// A floating announcements banner composed in the top `Column` of the overlay
/// `Stack` in `MaterialApp.router`'s `builder:` (see `app.dart`). Floating — it
/// overlaps the router content's top edge instead of reserving layout space, so
/// it never pushes a page's content down. Auth/onboarding are top-level routes
/// outside `AppShell`; composing it in the global overlay keeps the banner
/// visible across every route.
///
/// Watches [announcementsControllerProvider] and renders the active
/// [Announcement] via [AnnouncementBannerView]. Enter/exit motion is sourced
/// from [AppMotion] and guarded by [MediaQuery.disableAnimationsOf] with a
/// non-animated fallback that still toggles visibility. No widget calls a plugin
/// directly — the controller reads the settings store for dismiss persistence.
class AnnouncementBanner extends ConsumerStatefulWidget {
  const AnnouncementBanner({super.key});

  @override
  ConsumerState<AnnouncementBanner> createState() => _AnnouncementBannerState();
}

class _AnnouncementBannerState extends ConsumerState<AnnouncementBanner> {
  @override
  void initState() {
    super.initState();
    // Surface a transient toast when a dismiss fails to persist, then clear the
    // status so the transition can re-fire. Kept out of build (no side effects
    // in build) — mirrors ConnectivityBanner's recovery-toast listener.
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
    // Childless: renders only its own animated row. The overlay `Stack` in
    // `app.dart` pins it at the top and lets the router content fill the screen
    // behind it, so the banner floats over content instead of reserving space.
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
    // The banner lives below MaterialApp.router, so GoRouter.of resolves. The
    // route name comes from the Announcement's actionRoute string; navigation is
    // never gated on the enter/exit animation (audit #5).
    GoRouter.of(context).goNamed(route);
  }
}

/// The animated banner slot — renders [AnnouncementBannerView] for an active
/// announcement, or a zero-height placeholder when there is nothing to show.
/// Motion is sourced from [AppMotion] and guarded by
/// [MediaQuery.disableAnimationsOf] with a non-animated fallback that still
/// toggles visibility (so the message is never gated on the animation).
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
      // Non-animated fallback: visibility still toggles, just instantly.
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

/// The pure visual for one announcement. Rendered by [AnnouncementBanner]
/// (controller-driven, with real dismiss/goNamed callbacks) and by the
/// dev-gallery fixture (a fixed announcement with no-op callbacks), so the
/// preview is fully deterministic.
///
/// Uses [FAlert] for the status card (its `Directionality`-aware layout flips
/// the icon/title edge in RTL) plus trailing action + dismiss controls in a
/// [Row] — the row honors `Directionality`, so the CTA and dismiss button flip
/// to the leading edge in Arabic without manual mirroring.
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: FAlert(
                    variant: presentation.variant,
                    icon: Icon(
                      presentation.icon,
                      size: 18,
                      semanticLabel: presentation.severityLabel,
                    ),
                    title: Text(
                      announcement.title(translations),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      announcement.message(translations),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
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
          ),
        ),
      ),
    );
  }
}

/// Resolves the [FAlert] variant, leading icon, and accessible severity label
/// for [severity]. Exhaustive over [AnnouncementSeverity]; adding a value is a
/// compile error here until it is deliberately styled (audit #7). `info` /
/// `success` use the primary style; `warning` / `critical` use the destructive
/// style — distinct icons disambiguate all four severities.
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
