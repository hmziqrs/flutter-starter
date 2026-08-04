import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/settings/analytics_opt_in_controller.dart';
import 'package:starter/features/settings/widgets/settings_toggle_tile.dart';
import 'package:starter/i18n/translations.g.dart';

class AnalyticsOptInTile extends ConsumerWidget {
  const AnalyticsOptInTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translations = context.t;
    // The value-derived status text needs the current opt-in state, so the
    // provider is watched here for the status while SettingsToggleTile watches
    // it again for the switch value. The redundant subscription is harmless.
    final optedIn = ref.watch(analyticsOptInControllerProvider);
    final controller = ref.read(analyticsOptInControllerProvider.notifier);
    return SettingsToggleTile<bool>(
      watch: (ref) => ref.watch(analyticsOptInControllerProvider),
      valueSelector: (optedIn) => optedIn,
      onSave: (value) => controller.setOptIn(value: value),
      keyName: 'analytics',
      label: Text(translations.settings.analytics.optInTitle),
      description: Text(translations.settings.analytics.optInBody),
      status: optedIn
          ? translations.settings.analytics.statusOn
          : translations.settings.analytics.statusOff,
    );
  }
}
