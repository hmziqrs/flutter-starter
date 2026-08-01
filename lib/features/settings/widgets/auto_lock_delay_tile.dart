import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/settings/settings_controller.dart';
import 'package:starter/features/settings/widgets/settings_save_failure.dart';
import 'package:starter/features/settings/widgets/settings_toggle_card.dart';
import 'package:starter/i18n/translations.g.dart';

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
    final state = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    return SettingsToggleCard(
      keyName: 'auto-lock-delay',
      label: Text(translations.settings.autoLockDelay),
      status: _labelFor(translations, state.autoLockDelaySeconds),
      value: state.autoLockDelaySeconds > 0,
      onChange: (_) {
        if (!state.passcodeEnabled) return;
        final currentIndex = _options.indexOf(state.autoLockDelaySeconds);
        final nextIndex = (currentIndex + 1) % _options.length;
        unawaited(runSave(() => controller.setAutoLockDelaySeconds(_options[nextIndex])));
      },
      saveFailed: saveFailed,
    );
  }

  String _labelFor(Translations translations, int seconds) {
    if (seconds <= 0) return translations.settings.analytics.statusOff;
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    return '${minutes}m';
  }
}
