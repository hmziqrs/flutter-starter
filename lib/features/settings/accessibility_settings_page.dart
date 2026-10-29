import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/settings/settings_controller.dart';
import 'package:starter/features/settings/text_preset.dart';
import 'package:starter/features/settings/widgets/inline_save_error_text.dart';
import 'package:starter/features/settings/widgets/settings_row.dart';
import 'package:starter/features/settings/widgets/settings_save_failure.dart';
import 'package:starter/features/settings/widgets/settings_section_card.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/reading_content_scroll_frame.dart';
import 'package:starter/shared/widgets/spaced_column.dart';

class AccessibilitySettingsPage extends StatelessWidget {
  const AccessibilitySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // APP-BLOCKS.md app type scale: the page title is 24 w500 tight (display
    // .xl), matching the in-settings accessibility section.
    final style = context.theme.typography.display.xl;
    return SafeArea(
      bottom: false,
      child: ReadingContentScrollFrame(
        child: SpacedColumn(
          gap: context.spacing.lg,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.t.settings.accessibility.title,
              style: style.copyWith(
                fontWeight: FontWeight.w500,
                height: 1.25,
                letterSpacing: -(style.fontSize ?? 24) * 0.02,
              ),
            ),
            SizedBox(height: context.spacing.md),
            const AccessibilityPresetSelector(),
          ],
        ),
      ),
    );
  }
}

/// The text presets as quiet option rows (BRAND.md s7): a filled ring marker
/// means the picked preset; a failed save shows the inline soft error inside
/// the panel, never a silent failure.
///
/// The section card carries no title of its own: both compositions (this page
/// and the settings accessibility section) already name the group with their
/// page title, so a card title would stack the same words twice
/// (SettingsSectionCard's own contract).
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
    final selected = ref.watch(
      settingsControllerProvider.select((state) => state.textPreset),
    );
    final controller = ref.read(settingsControllerProvider.notifier);

    return SettingsSectionCard(
      children: [
        for (final preset in AppTextPreset.values)
          SettingsOptionRow(
            rowKey: ValueKey('a11y-preset-${preset.name}'),
            label: _PresetLabels.title(translations, preset),
            description: _PresetLabels.description(translations, preset),
            selected: preset == selected,
            onPress: () => runSave(() => controller.setTextPreset(preset)),
          ),
        if (saveFailed)
          InlineSaveErrorText(
            message: translations.settings.saveFailure,
            valueKey: 'a11y-preset-save-error',
          ),
      ],
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
