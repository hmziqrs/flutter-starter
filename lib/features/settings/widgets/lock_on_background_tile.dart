import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/settings/settings_controller.dart';
import 'package:starter/features/settings/widgets/settings_save_failure.dart';
import 'package:starter/features/settings/widgets/settings_toggle_card.dart';
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
    final state = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    return SettingsToggleCard(
      keyName: 'lock-on-background',
      label: Text(translations.settings.lockOnBackground),
      value: state.lockOnBackground,
      onChange: (value) {
        if (!state.passcodeEnabled) return;
        unawaited(runSave(() => controller.setLockOnBackground(enabled: value)));
      },
      saveFailed: saveFailed,
    );
  }
}
