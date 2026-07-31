import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/force_update/force_update_state.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/escape_dismissible_overlay.dart';

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

abstract final class SoftUpdateSnooze {
  static const String key = 'update.snoozed_until';

  static const Duration defaultDuration = Duration(days: 1);

  static String encode({DateTime? at, Duration duration = defaultDuration}) {
    final start = (at ?? DateTime.now()).toUtc();
    return start.add(duration).toIso8601String();
  }

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
