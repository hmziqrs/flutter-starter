import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/app_spacing.dart';

class SettingsToggleCard extends StatelessWidget {
  const SettingsToggleCard({
    required this.keyName,
    required this.label,
    required this.value,
    required this.onChange,
    required this.saveFailed,
    this.description,
    this.status,
    super.key,
  });

  final String keyName;
  final Widget label;
  final Widget? description;
  final String? status;
  final bool value;
  final ValueChanged<bool> onChange;
  final bool saveFailed;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FSwitch(
              key: ValueKey('settings-toggle-$keyName'),
              value: value,
              label: label,
              description: description,
              onChange: onChange,
            ),
            if (status case final status?) ...[
              const SizedBox(height: AppSpacing.md),
              Text(status, style: context.theme.typography.body.sm),
            ],
            if (saveFailed) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                translations.common.notConnected,
                key: const ValueKey('settings-toggle-save-error'),
                style: context.theme.typography.body.sm.copyWith(
                  color: context.theme.colors.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
