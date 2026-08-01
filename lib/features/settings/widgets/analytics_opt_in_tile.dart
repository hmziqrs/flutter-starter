import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/settings/analytics_opt_in_controller.dart';
import 'package:starter/features/settings/widgets/settings_save_failure.dart';
import 'package:starter/features/settings/widgets/settings_toggle_card.dart';
import 'package:starter/i18n/translations.g.dart';

class AnalyticsOptInTile extends ConsumerStatefulWidget {
  const AnalyticsOptInTile({super.key});

  @override
  ConsumerState<AnalyticsOptInTile> createState() => _AnalyticsOptInTileState();
}

class _AnalyticsOptInTileState extends ConsumerState<AnalyticsOptInTile>
    with SettingsSaveFailureState {
  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final optedIn = ref.watch(analyticsOptInControllerProvider);
    final controller = ref.read(analyticsOptInControllerProvider.notifier);
    return SettingsToggleCard(
      keyName: 'analytics',
      label: Text(translations.settings.analytics.optInTitle),
      description: Text(translations.settings.analytics.optInBody),
      status: optedIn
          ? translations.settings.analytics.statusOn
          : translations.settings.analytics.statusOff,
      value: optedIn,
      onChange: (value) => runSave(() => controller.setOptIn(value: value)),
      saveFailed: saveFailed,
    );
  }
}
