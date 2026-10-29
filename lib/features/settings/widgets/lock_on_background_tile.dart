import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/settings/settings_controller.dart';
import 'package:starter/features/settings/widgets/settings_save_failure.dart';
import 'package:starter/features/settings/widgets/settings_switch_row.dart';
import 'package:starter/i18n/translations.g.dart';

class LockOnBackgroundTile extends ConsumerStatefulWidget {
  const LockOnBackgroundTile({super.key});

  @override
  ConsumerState<LockOnBackgroundTile> createState() => _LockOnBackgroundTileState();
}

class _LockOnBackgroundTileState extends ConsumerState<LockOnBackgroundTile>
    with SettingsSaveFailureState {
  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final state = ref.watch(
      settingsControllerProvider.select(
        (s) => (lockOnBackground: s.lockOnBackground, passcodeEnabled: s.passcodeEnabled),
      ),
    );
    final controller = ref.read(settingsControllerProvider.notifier);
    final passcodeEnabled = state.passcodeEnabled;
    return SettingsSwitchRow(
      keyName: 'lock-on-background',
      label: translations.settings.lockOnBackground,
      // Without a passcode there is nothing to lock with: disable the row and
      // say how to get there (BRAND.md s9, s11) instead of swallowing taps.
      description: passcodeEnabled ? null : translations.settings.requiresPasscode,
      enabled: passcodeEnabled,
      value: state.lockOnBackground,
      onChange: (value) {
        if (!passcodeEnabled) return;
        unawaited(runSave(() => controller.setLockOnBackground(enabled: value)));
      },
      saveFailed: saveFailed,
    );
  }
}
