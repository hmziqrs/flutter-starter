import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/settings/settings_controller.dart';
import 'package:starter/features/settings/widgets/inline_save_error_text.dart';
import 'package:starter/features/settings/widgets/settings_save_failure.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/widgets/blocks/segmented.dart';

/// The auto-lock delay as what it is — a choice of four delays, picked with
/// the brand segmented control (BRAND.md s8), not a switch that cycles
/// through values its checked state doesn't describe.
///
/// With no passcode set there is nothing to lock with, so the row is quiet
/// and inert with a muted hint saying how to get there (BRAND.md s9, s11) —
/// never a control that silently swallows taps.
class AutoLockDelayTile extends ConsumerStatefulWidget {
  const AutoLockDelayTile({super.key});

  @override
  ConsumerState<AutoLockDelayTile> createState() => _AutoLockDelayTileState();
}

class _AutoLockDelayTileState extends ConsumerState<AutoLockDelayTile>
    with SettingsSaveFailureState {
  static const _options = <int>[0, 30, 60, 300];

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final theme = context.theme;
    final state = ref.watch(
      settingsControllerProvider.select(
        (s) => (autoLockDelaySeconds: s.autoLockDelaySeconds, passcodeEnabled: s.passcodeEnabled),
      ),
    );
    final controller = ref.read(settingsControllerProvider.notifier);

    if (!state.passcodeEnabled) {
      return Padding(
        key: const ValueKey('settings-auto-lock-inert'),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 20, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              translations.settings.autoLockDelay,
              style: theme.typography.body.sm.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colors.mutedForeground,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              translations.settings.requiresPasscode,
              style: theme.typography.body.sm.copyWith(color: theme.colors.mutedForeground),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                translations.settings.autoLockDelay,
                style: theme.typography.body.sm.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              AppSegmented<int>(
                options: [
                  for (final seconds in _options)
                    (
                      value: seconds,
                      label: _labelFor(translations, seconds),
                      key: ValueKey('auto-lock-$seconds'),
                    ),
                ],
                value: state.autoLockDelaySeconds,
                onChanged: (seconds) => runSave(() => controller.setAutoLockDelaySeconds(seconds)),
              ),
            ],
          ),
        ),
        if (saveFailed)
          InlineSaveErrorText(
            message: translations.settings.saveFailure,
            valueKey: 'auto-lock-save-error',
          ),
      ],
    );
  }

  String _labelFor(Translations translations, int seconds) {
    if (seconds <= 0) return translations.settings.analytics.statusOff;
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    return '${minutes}m';
  }
}
