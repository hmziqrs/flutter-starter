import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/settings/widgets/inline_save_error_text.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/brand/app_ring_marker.dart';
import 'package:starter/shared/widgets/containers/app_card.dart';

/// A quiet settings row: the switch, an on/off status line, and a soft
/// destructive note when the save failed.
class SettingsToggleCard extends StatelessWidget {
  const SettingsToggleCard({
    required this.keyName,
    required this.label,
    required this.value,
    required this.onChange,
    required this.saveFailed,
    this.description,
    this.status,
    super.key,
  });

  final String keyName;
  final Widget label;
  final Widget? description;
  final String? status;
  final bool value;
  final ValueChanged<bool> onChange;
  final bool saveFailed;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FSwitch(
            key: ValueKey('settings-toggle-$keyName'),
            value: value,
            label: label,
            description: description,
            onChange: onChange,
          ),
          if (status case final status?) ...[
            SizedBox(height: context.spacing.md),
            _RingStatusLine(status: status, on: value),
          ],
          if (saveFailed) ...[
            SizedBox(height: context.spacing.sm),
            InlineSaveErrorText(
              message: translations.common.notConnected,
              valueKey: 'settings-toggle-save-error',
            ),
          ],
        ],
      ),
    );
  }
}

/// Status with text: a ring marker (filled means on) beside muted words.
class _RingStatusLine extends StatelessWidget {
  const _RingStatusLine({required this.status, required this.on});

  final String status;
  final bool on;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Row(
      children: [
        AppRingMarker(filled: on, color: on ? colors.primary : colors.mutedForeground),
        SizedBox(width: context.spacing.sm),
        Text(
          status,
          style: context.theme.typography.body.sm.copyWith(color: colors.mutedForeground),
        ),
      ],
    );
  }
}
