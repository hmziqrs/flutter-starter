import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/features/settings/accessibility_settings_page.dart';
import 'package:starter/features/settings/in_memory_settings_store.dart';
import 'package:starter/features/settings/settings_controller.dart';
import 'package:starter/features/settings/settings_repository.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/features/settings/text_preset.dart';
import 'package:starter/i18n/translations.g.dart';

/// Builds the accessibility-preset gallery cases (comfortable / large /
/// dyslexia). Each case seeds the settings controller with an in-memory store
/// so taps never touch real persistence.
List<GalleryCase> buildA11yPresetsGalleryCases() {
  return [
    for (final preset in AppTextPreset.values)
      TypedGalleryCase<AppTextPreset>(
        id: 'accessibility.${preset.name}',
        screenId: 'accessibility',
        screenLabelBuilder: (translations) => translations.devGallery.screenAccessibility,
        caseLabelBuilder: (translations) => _caseLabel(translations, preset),
        stateFactory: (_) => preset,
        pageFactory: (context, state) => _AccessibilityPresetPreview(preset: state),
      ),
  ];
}

String _caseLabel(Translations t, AppTextPreset preset) => switch (preset) {
  AppTextPreset.comfortable => t.devGallery.caseAccessibilityComfortable,
  AppTextPreset.large => t.devGallery.caseAccessibilityLarge,
  AppTextPreset.dyslexia => t.devGallery.caseAccessibilityDyslexia,
};

/// Pins [AccessibilitySettingsPage] to a preset-selected state so the
/// selection highlight is deterministic on first frame.
class _AccessibilityPresetPreview extends StatelessWidget {
  const _AccessibilityPresetPreview({required this.preset});

  final AppTextPreset preset;

  @override
  Widget build(BuildContext context) {
    final settings = preset.toSettings();
    return ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(
          SettingsRepository(InMemorySettingsStore()),
        ),
        initialSettingsProvider.overrideWithValue(
          const SettingsState.defaults().copyWith(
            textPreset: preset,
            fontScale: settings.fontScale,
          ),
        ),
      ],
      child: const AccessibilitySettingsPage(),
    );
  }
}
