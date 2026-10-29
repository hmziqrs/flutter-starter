import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/settings/widgets/inline_save_error_text.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/widgets/brand/app_ring_marker.dart';

/// A quiet toggle row (APP-BLOCKS.md "SettingRow", horizontal): the label
/// and its muted description on the left, the switch on the right, and a
/// ring-marker status line for values that read better as words than as a
/// switch position ("On", "5m").
///
/// The switch is the one control: it owns focus, keyboard toggling and the
/// merged toggle semantics, named by the label. Feedback is color only.
///
/// A row whose setting cannot apply right now (no passcode, no biometrics)
/// is disabled — visibly, with a muted description saying why and the way
/// back (BRAND.md s9, s11) — never a control that silently swallows taps.
class SettingsSwitchRow extends StatelessWidget {
  const SettingsSwitchRow({
    required this.keyName,
    required this.label,
    required this.value,
    required this.onChange,
    this.description,
    this.statusText,
    this.saveFailed = false,
    this.enabled = true,
    super.key,
  });

  /// Names the switch's [ValueKey], `settings-toggle-<keyName>`.
  final String keyName;

  /// The row's label; also the switch's accessible name.
  final String label;

  /// One muted sentence under the label.
  final String? description;

  /// A status line under the label: a ring marker (filled means on) beside
  /// muted words.
  final String? statusText;

  final bool value;

  final ValueChanged<bool> onChange;

  /// Whether the last save failed; shows the inline soft error under the row.
  final bool saveFailed;

  /// False when the setting cannot apply (e.g. no passcode set): the switch
  /// renders in its disabled style and cannot be toggled.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: theme.typography.body.sm.copyWith(
                        fontWeight: FontWeight.w500,
                        // A disabled row reads as secondary next to its hint.
                        color: enabled ? null : theme.colors.mutedForeground,
                      ),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        description!,
                        style: theme.typography.body.sm.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                    ],
                    if (statusText != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppRingMarker(
                            filled: value,
                            color: value ? theme.colors.primary : theme.colors.mutedForeground,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            statusText!,
                            style: theme.typography.body.sm.copyWith(
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              FSwitch(
                key: ValueKey('settings-toggle-$keyName'),
                value: value,
                // A null onChange is how FSwitch renders and behaves disabled.
                onChange: enabled ? onChange : null,
                semanticsLabel: label,
              ),
            ],
          ),
        ),
        if (saveFailed)
          InlineSaveErrorText(
            message: context.t.settings.saveFailure,
            valueKey: 'settings-toggle-save-error',
          ),
      ],
    );
  }
}
