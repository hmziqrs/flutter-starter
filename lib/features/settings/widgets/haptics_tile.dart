import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/settings/settings_controller.dart';
import 'package:starter/features/settings/widgets/settings_save_failure.dart';
import 'package:starter/features/settings/widgets/settings_toggle_card.dart';
import 'package:starter/i18n/translations.g.dart';

class HapticsTile extends ConsumerStatefulWidget {
  const HapticsTile({super.key});

  @override
  ConsumerState<HapticsTile> createState() => _HapticsTileState();
}

class _HapticsTileState extends ConsumerState<HapticsTile> with SettingsSaveFailureState {
  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final enabled = ref.watch(settingsControllerProvider).hapticsEnabled;
    final controller = ref.read(settingsControllerProvider.notifier);
    return SettingsToggleCard(
      keyName: 'haptics',
      label: Text(translations.settings.haptics.title),
      description: Text(translations.settings.haptics.enable),
      value: enabled,
      onChange: (value) => runSave(() => controller.setHapticsEnabled(enabled: value)),
      saveFailed: saveFailed,
    );
  }
}
