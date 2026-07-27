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

/// Immutable, deterministic preview state for the accessibility-preset gallery
/// cases. One per [AppTextPreset]; no timers, no plugin, no real persistence
/// (an [InMemorySettingsStore] backs the seeded controller so taps persist
/// in-memory only and the preview stays stable across frames).
final class AccessibilityPresetGalleryState {
  const AccessibilityPresetGalleryState._(this.preset, this.labelBuilder);

  final AppTextPreset preset;
  final String Function(Translations translations) labelBuilder;

  static final comfortable = AccessibilityPresetGalleryState._(
    AppTextPreset.comfortable,
    (t) => t.devGallery.caseAccessibilityComfortable,
  );
  static final large = AccessibilityPresetGalleryState._(
    AppTextPreset.large,
    (t) => t.devGallery.caseAccessibilityLarge,
  );
  static final dyslexia = AccessibilityPresetGalleryState._(
    AppTextPreset.dyslexia,
    (t) => t.devGallery.caseAccessibilityDyslexia,
  );

  static final values = <AccessibilityPresetGalleryState>[
    comfortable,
    large,
    dyslexia,
  ];
}

/// Builds the accessibility-preset gallery cases (comfortable / large /
/// dyslexia). Each case seeds [settingsControllerProvider] with the named
/// preset selected and mounts the production [AccessibilitySettingsPage]; an
/// [InMemorySettingsStore] backs the repository so taps persist in-memory only
/// (no real keychain, no backend — C2 gallery discipline).
List<GalleryCase> buildA11yPresetsGalleryCases() {
  return [
    for (final entry in AccessibilityPresetGalleryState.values)
      TypedGalleryCase<AccessibilityPresetGalleryState>(
        id: 'accessibility.${entry.preset.name}',
        screenId: 'accessibility',
        screenLabelBuilder: (translations) => translations.devGallery.screenAccessibility,
        caseLabelBuilder: entry.labelBuilder,
        stateFactory: (_) => entry,
        pageFactory: (context, state) => _AccessibilityPresetPreview(state: state),
      ),
  ];
}

/// Pins [AccessibilitySettingsPage] to a preset-selected state inside a nested
/// [ProviderScope]. The PreviewFrame already provides a ProviderScope
/// (interactionPolicy); this nests one that seeds the settings controller with
/// the preset's resolved `(fontScale, fontFamily)` so the selection highlight
/// is deterministic on first frame.
class _AccessibilityPresetPreview extends StatelessWidget {
  const _AccessibilityPresetPreview({required this.state});

  final AccessibilityPresetGalleryState state;

  @override
  Widget build(BuildContext context) {
    final settings = state.preset.toSettings();
    return ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(
          SettingsRepository(InMemorySettingsStore()),
        ),
        initialSettingsProvider.overrideWithValue(
          const SettingsState.defaults().copyWith(
            textPreset: state.preset,
            fontScale: settings.fontScale,
          ),
        ),
      ],
      child: const AccessibilitySettingsPage(),
    );
  }
}
