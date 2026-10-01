import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:starter/features/announcements/announcement_view_data.dart';
import 'package:starter/features/announcements/announcements_controller.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/app_spacing.dart';
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

class AnnouncementBannerView extends StatefulWidget {
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
  State<AnnouncementBannerView> createState() => _AnnouncementBannerViewState();
}

class _AnnouncementBannerViewState extends State<AnnouncementBannerView> {
  double _actionsExtent = 0;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final presentation = _presentationFor(widget.announcement.severity, translations);
    final actionRoute = widget.announcement.actionRoute;
    final spacing = context.spacing;
    final textExtentReserve = _actionsExtent == 0 ? 0.0 : _actionsExtent + spacing.sm;

    return Semantics(
      container: true,
      liveRegion: true,
      label:
          '${widget.announcement.title(translations)}. ${widget.announcement.message(translations)}',
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.lg,
              vertical: spacing.sm,
            ),
            child: SizedBox(
              width: double.infinity,
              child: Stack(
                children: [
                  IgnorePointer(
                    child: FAlert(
                      variant: presentation.variant,
                      icon: Icon(
                        presentation.icon,
                        size: 18,
                        semanticLabel: presentation.severityLabel,
                      ),
                      title: _reserveActionsExtent(
                        Text(
                          widget.announcement.title(translations),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        textExtentReserve,
                      ),
                      subtitle: _reserveActionsExtent(
                        Text(
                          widget.announcement.message(translations),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                        textExtentReserve,
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    top: spacing.xs,
                    end: spacing.xs,
                    child: _MeasuredWidth(
                      onMeasured: _updateActionsExtent,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (actionRoute != null) ...[
                            FButton(
                              key: const ValueKey('announcement-action'),
                              variant: .outline,
                              size: .sm,
                              onPress: widget.onAction,
                              child: Text(translations.announcements.actionLearnMore),
                            ),
                            SizedBox(width: spacing.sm),
                          ],
                          if (widget.announcement.dismissible)
                            FButton.icon(
                              key: const ValueKey('announcement-dismiss'),
                              variant: .ghost,
                              size: .sm,
                              semanticsLabel: translations.announcements.dismiss,
                              onPress: widget.onDismiss,
                              child: const Icon(FLucideIcons.x, size: 16),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _updateActionsExtent(double extent) {
    if (extent == _actionsExtent) {
      return;
    }
    setState(() => _actionsExtent = extent);
  }

  Widget _reserveActionsExtent(Widget text, double extent) {
    if (extent == 0) {
      return text;
    }
    return Padding(
      padding: EdgeInsetsDirectional.only(end: extent),
      child: text,
    );
  }
}

class _MeasuredWidth extends SingleChildRenderObjectWidget {
  const _MeasuredWidth({required this.onMeasured, super.child});

  final ValueChanged<double> onMeasured;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderMeasuredWidth(onMeasured);

  @override
  void updateRenderObject(BuildContext context, covariant _RenderMeasuredWidth renderObject) {
    renderObject.onMeasured = onMeasured;
  }
}

class _RenderMeasuredWidth extends RenderProxyBox {
  _RenderMeasuredWidth(this.onMeasured);

  ValueChanged<double> onMeasured;

  double? _reportedWidth;

  @override
  void performLayout() {
    super.performLayout();
    final width = child?.size.width ?? 0;
    if (width == _reportedWidth) {
      return;
    }
    _reportedWidth = width;
    WidgetsBinding.instance.addPostFrameCallback((_) => onMeasured(width));
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
