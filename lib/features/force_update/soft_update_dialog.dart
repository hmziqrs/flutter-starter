import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/force_update/force_update_state.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/escape_dismissible_overlay.dart';

/// The dismissible soft-deprecation nudge for deprecated builds.
///
/// Reuses [EscapeDismissibleOverlay] + [FDialog] (mirroring the router's
/// `_showInformationDialog`) rather than extracting any new shared widget (C3:
/// shared extraction needs >=3 concrete consumers). The dialog body is the
/// reusable [SoftUpdateCard], also rendered directly by the dev-gallery fixture
/// so the soft state is deterministically previewable. The dialog performs no
/// side effects and calls no plugin: [onUpdate] / [onLater] are supplied by the
/// composition root (store deep-link + snooze persistence respectively).

/// Shows the soft-update [FDialog]. Dismissible via Escape / barrier; the
/// caller's [onUpdate] / [onLater] callbacks run after the dialog is dismissed.
Future<void> showSoftUpdateDialog(
  BuildContext context, {
  required ForceUpdateState state,
  required VoidCallback onUpdate,
  required VoidCallback onLater,
}) {
  final translations = context.t;
  return showFDialog<void>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    builder: (context, style, animation) => EscapeDismissibleOverlay(
      child: FDialog(
        key: const ValueKey('soft-update-dialog'),
        animation: animation,
        semanticsLabel: translations.softUpdate.title,
        builder: (context, style) => Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: SoftUpdateCard(
            state: state,
            titleStyle: style.titleTextStyle,
            bodyStyle: style.bodyTextStyle,
            onUpdate: () {
              Navigator.of(context).pop();
              onUpdate();
            },
            onLater: () {
              Navigator.of(context).pop();
              onLater();
            },
          ),
        ),
      ),
    ),
  );
}

/// The soft-update dialog body: title, body (or server message), and the
/// "Update" / "Later" actions. Rendered both inside [showSoftUpdateDialog] and
/// directly by the dev-gallery soft fixture.
class SoftUpdateCard extends StatelessWidget {
  const SoftUpdateCard({
    required this.state,
    required this.onUpdate,
    required this.onLater,
    this.titleStyle,
    this.bodyStyle,
    super.key,
  });

  final ForceUpdateState state;
  final VoidCallback onUpdate;
  final VoidCallback onLater;
  final TextStyle? titleStyle;
  final TextStyle? bodyStyle;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          translations.softUpdate.title,
          key: const ValueKey('soft-update-title'),
          style: titleStyle ?? context.theme.typography.display.lg,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          state.message ?? translations.softUpdate.body,
          key: const ValueKey('soft-update-body'),
          style: bodyStyle,
        ),
        const SizedBox(height: AppSpacing.xl),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            FButton(
              key: const ValueKey('soft-update-later'),
              variant: FButtonVariant.outline,
              mainAxisSize: MainAxisSize.min,
              onPress: onLater,
              child: Text(translations.softUpdate.later),
            ),
            FButton(
              key: const ValueKey('soft-update-update'),
              mainAxisSize: MainAxisSize.min,
              onPress: onUpdate,
              child: Text(translations.softUpdate.update),
            ),
          ],
        ),
      ],
    );
  }
}

/// Pure, side-effect-free helpers for the soft-update snooze timestamp.
///
/// The feature owns the encoding/decoding math; the composition root owns the
/// actual `SettingsStore` read/write (the feature must not import another
/// feature's port). Snoozing persists `update.snoozed_until` so a dismissed soft
/// prompt does not re-appear every launch — otherwise it becomes a UX nuisance.
abstract final class SoftUpdateSnooze {
  /// Settings key holding the snooze deadline (UTC ISO-8601).
  static const String key = 'update.snoozed_until';

  /// How long a dismissed soft prompt stays suppressed.
  static const Duration defaultDuration = Duration(days: 1);

  /// Encodes a snooze deadline [duration] from [at] (defaults to now).
  static String encode({DateTime? at, Duration duration = defaultDuration}) {
    final start = (at ?? DateTime.now()).toUtc();
    return start.add(duration).toIso8601String();
  }

  /// Returns `true` when [stored] is a future timestamp relative to [now].
  /// `null` / unparseable values are treated as not snoozed.
  static bool isSnoozed(String? stored, {DateTime? now}) {
    if (stored == null) {
      return false;
    }
    final until = DateTime.tryParse(stored);
    if (until == null) {
      return false;
    }
    return (now ?? DateTime.now()).isBefore(until);
  }
}
