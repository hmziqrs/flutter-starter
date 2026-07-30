import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/features/notifications/notification_permission_status.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/app_spacing.dart';

/// Preview state for the notifications permission rationale gallery cases:
/// one variant per [NotificationPermissionStatus].
final class NotificationsGalleryState {
  const NotificationsGalleryState._({
    required this.permission,
    required this.labelBuilder,
  });

  final NotificationPermissionStatus permission;
  final String Function(Translations translations) labelBuilder;

  static final notRequested = NotificationsGalleryState._(
    permission: NotificationPermissionStatus.notRequested,
    labelBuilder: (t) => t.notifications.enableTitle,
  );

  static final granted = NotificationsGalleryState._(
    permission: NotificationPermissionStatus.granted,
    labelBuilder: (t) => t.notifications.allow,
  );

  static final denied = NotificationsGalleryState._(
    permission: NotificationPermissionStatus.denied,
    labelBuilder: (t) => t.notifications.deny,
  );

  static final values = <NotificationsGalleryState>[notRequested, granted, denied];
}

/// Builds the notifications permission rationale gallery cases
/// (not-requested / granted / denied) as static copy, previewable without a
/// live `NotificationsRepository` or plugin.
List<GalleryCase> buildNotificationsGalleryCases() {
  return [
    for (final entry in NotificationsGalleryState.values)
      TypedGalleryCase<NotificationsGalleryState>(
        id: 'notifications.${entry.permission.name}',
        screenId: 'notifications',
        screenLabelBuilder: (translations) => translations.devGallery.screenNotifications,
        caseLabelBuilder: entry.labelBuilder,
        stateFactory: (_) => entry,
        pageFactory: (context, state) => _NotificationsRationalePreview(state: state),
      ),
  ];
}

class _NotificationsRationalePreview extends StatelessWidget {
  const _NotificationsRationalePreview({required this.state});

  final NotificationsGalleryState state;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final notifications = translations.notifications;
    final permission = state.permission;
    final isBlocked = permission.showsOpenSettings;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: FCard(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isBlocked ? notifications.enableBlockedTitle : notifications.enableTitle,
                    style: context.theme.typography.display.lg,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    isBlocked ? notifications.enableBlockedBody : notifications.enableBody,
                    style: context.theme.typography.body.sm,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _StatusChip(label: notifications.deny),
                      _StatusChip(label: notifications.allow),
                    ],
                  ),
                  if (permission == NotificationPermissionStatus.notRequested) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      notifications.disabled,
                      style: context.theme.typography.body.xs,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border.all(color: context.theme.colors.border),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Text(label, style: context.theme.typography.body.sm),
    );
  }
}
