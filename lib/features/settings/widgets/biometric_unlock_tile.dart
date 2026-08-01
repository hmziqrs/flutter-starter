import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/settings/settings_controller.dart';
import 'package:starter/features/settings/widgets/settings_save_failure.dart';
import 'package:starter/features/settings/widgets/settings_toggle_card.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/biometric/biometric_authenticator_provider.dart';

class BiometricUnlockTile extends ConsumerStatefulWidget {
  const BiometricUnlockTile({super.key});

  @override
  ConsumerState<BiometricUnlockTile> createState() => _BiometricUnlockTileState();
}

class _BiometricUnlockTileState extends ConsumerState<BiometricUnlockTile>
    with SettingsSaveFailureState {
  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final enabled = ref.watch(settingsControllerProvider).biometricUnlockEnabled;
    final controller = ref.read(settingsControllerProvider.notifier);
    final availability = ref.watch(biometricAvailabilityProvider);
    final canCheck = availability.maybeWhen(
      data: (report) => report.canCheck,
      orElse: () => false,
    );
    return SettingsToggleCard(
      keyName: 'biometric',
      label: Text(translations.settings.enableBiometric),
      value: enabled,
      onChange: (value) {
        if (value && !canCheck) return;
        unawaited(runSave(() => controller.setBiometricUnlockEnabled(enabled: value)));
      },
      saveFailed: saveFailed,
    );
  }
}
