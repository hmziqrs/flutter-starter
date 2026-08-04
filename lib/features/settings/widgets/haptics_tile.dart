import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/settings/settings_controller.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/features/settings/widgets/settings_toggle_tile.dart';
import 'package:starter/i18n/translations.g.dart';

class HapticsTile extends ConsumerWidget {
  const HapticsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translations = context.t;
    final controller = ref.read(settingsControllerProvider.notifier);
    return SettingsToggleTile<SettingsState>(
      watch: (ref) => ref.watch(settingsControllerProvider),
      valueSelector: (state) => state.hapticsEnabled,
      onSave: (value) => controller.setHapticsEnabled(enabled: value),
      keyName: 'haptics',
      label: Text(translations.settings.haptics.title),
      description: Text(translations.settings.haptics.enable),
    );
  }
}
