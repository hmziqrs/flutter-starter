import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/security/passcode_controller.dart';
import 'package:starter/features/settings/settings_controller.dart';
import 'package:starter/features/settings/widgets/settings_save_failure.dart';
import 'package:starter/features/settings/widgets/settings_toggle_card.dart';
import 'package:starter/i18n/translations.g.dart';

class PasscodeTile extends ConsumerStatefulWidget {
  const PasscodeTile({required this.onOpenSetup, super.key});

  final VoidCallback onOpenSetup;

  @override
  ConsumerState<PasscodeTile> createState() => _PasscodeTileState();
}

class _PasscodeTileState extends ConsumerState<PasscodeTile> with SettingsSaveFailureState {
  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final enabled = ref.watch(settingsControllerProvider).passcodeEnabled;
    final controller = ref.read(settingsControllerProvider.notifier);
    return SettingsToggleCard(
      keyName: 'passcode',
      label: Text(translations.settings.passcode),
      value: enabled,
      onChange: (value) async {
        if (value) {
          await runSave(() => controller.setPasscodeEnabled(enabled: true));
          if (context.mounted) widget.onOpenSetup();
        } else {
          await runSave(() async {
            await ref.read(passcodeControllerProvider.notifier).disable();
            await controller.setPasscodeEnabled(enabled: false);
          });
        }
      },
      saveFailed: saveFailed,
    );
  }
}
