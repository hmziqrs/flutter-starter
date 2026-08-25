import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/settings/settings_controller.dart';
import 'package:starter/features/settings/text_preset.dart';
import 'package:starter/features/settings/widgets/labeled_section_card.dart';
import 'package:starter/features/settings/widgets/settings_save_failure.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/reading_content_scroll_frame.dart';
import 'package:starter/shared/widgets/spaced_column.dart';

class AccessibilitySettingsPage extends StatelessWidget {
  const AccessibilitySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ReadingContentScrollFrame(
        title: context.t.settings.accessibility.title,
        child: const AccessibilityPresetSelector(),
      ),
    );
  }
}

class AccessibilityPresetSelector extends ConsumerStatefulWidget {
  const AccessibilityPresetSelector({super.key});

  @override
  ConsumerState<AccessibilityPresetSelector> createState() => _AccessibilityPresetSelectorState();
}

class _AccessibilityPresetSelectorState extends ConsumerState<AccessibilityPresetSelector>
    with SettingsSaveFailureState<AccessibilityPresetSelector> {
  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final selected = settings.textPreset;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabeledSectionCard(
          title: translations.settings.accessibility.title,
          child: SpacedColumn(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final preset in AppTextPreset.values)
                _PresetTile(
                  preset: preset,
                  selected: preset == selected,
                  onPress: () => runSave(() => controller.setTextPreset(preset)),
                ),
            ],
          ),
        ),
        if (saveFailed) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            translations.common.notConnected,
            key: const ValueKey('a11y-preset-save-error'),
            style: context.theme.typography.body.sm.copyWith(
              color: context.theme.colors.error,
            ),
          ),
        ],
      ],
    );
  }
}

class _PresetTile extends StatelessWidget {
  const _PresetTile({
    required this.preset,
    required this.selected,
    required this.onPress,
  });

  final AppTextPreset preset;
  final bool selected;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    return FTile(
      key: ValueKey('a11y-preset-${preset.name}'),
      title: Text(_PresetLabels.title(translations, preset)),
      subtitle: Text(_PresetLabels.description(translations, preset)),
      suffix: Icon(
        selected ? FLucideIcons.circleCheck : FLucideIcons.circle,
        semanticLabel: selected ? translations.common.done : null,
      ),
      selected: selected,
      onPress: onPress,
    );
  }
}

final class _PresetLabels {
  const _PresetLabels._();

  static String title(Translations translations, AppTextPreset preset) {
    return switch (preset) {
      AppTextPreset.comfortable => translations.settings.accessibility.preset.comfortable,
      AppTextPreset.large => translations.settings.accessibility.preset.large,
      AppTextPreset.dyslexia => translations.settings.accessibility.preset.dyslexia,
    };
  }

  static String description(Translations translations, AppTextPreset preset) {
    return switch (preset) {
      AppTextPreset.comfortable =>
        translations.settings.accessibility.preset.comfortableDescription,
      AppTextPreset.large => translations.settings.accessibility.preset.largeDescription,
      AppTextPreset.dyslexia => translations.settings.accessibility.preset.dyslexiaDescription,
    };
  }
}
