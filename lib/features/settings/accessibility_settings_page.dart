import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/settings/settings_controller.dart';
import 'package:starter/features/settings/text_preset.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/app_sizes.dart';
import 'package:starter/shared/theme/app_spacing.dart';

/// Standalone accessibility-settings surface (gallery/tests). The live app
/// renders the same [AccessibilityPresetSelector] in-pane on `SettingsPage`.
class AccessibilitySettingsPage extends StatelessWidget {
  const AccessibilitySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: _AccessibilityScrollFrame(
        title: context.t.settings.accessibility.title,
        child: const AccessibilityPresetSelector(),
      ),
    );
  }
}

/// Named text-preset selector (comfortable / large / dyslexia). Selecting a
/// preset persists via `SettingsController.setTextPreset`, surfacing
/// `common.notConnected` on failure.
class AccessibilityPresetSelector extends ConsumerStatefulWidget {
  const AccessibilityPresetSelector({super.key});

  @override
  ConsumerState<AccessibilityPresetSelector> createState() => _AccessibilityPresetSelectorState();
}

class _AccessibilityPresetSelectorState extends ConsumerState<AccessibilityPresetSelector> {
  bool _saveFailed = false;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final selected = settings.textPreset;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AccessibilityCard(
          title: translations.settings.accessibility.title,
          child: _SpacedTiles(
            children: [
              for (final preset in AppTextPreset.values)
                _PresetTile(
                  preset: preset,
                  selected: preset == selected,
                  onPress: () => _run(() => controller.setTextPreset(preset)),
                ),
            ],
          ),
        ),
        if (_saveFailed) ...[
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

  Future<void> _run(Future<void> Function() operation) async {
    try {
      await operation();
      if (mounted) {
        setState(() => _saveFailed = false);
      }
    } on Object {
      if (mounted) {
        setState(() => _saveFailed = true);
      }
    }
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

/// Localized labels for [AppTextPreset]. Exhaustive switch keeps strict
/// analysis happy when a new variant is added.
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

class _AccessibilityScrollFrame extends StatelessWidget {
  const _AccessibilityScrollFrame({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsetsDirectional.fromSTEB(
        context.spacing.xl,
        context.spacing.xl,
        context.spacing.xl,
        context.spacing.xl2,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.readingContentMaxWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: context.theme.typography.display.xl2),
                SizedBox(height: context.spacing.xl),
                child,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AccessibilityCard extends StatelessWidget {
  const _AccessibilityCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: context.theme.typography.body.lg),
            const SizedBox(height: AppSpacing.lg),
            child,
          ],
        ),
      ),
    );
  }
}

class _SpacedTiles extends StatelessWidget {
  const _SpacedTiles({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < children.length; index++) ...[
          if (index > 0) const SizedBox(height: AppSpacing.sm),
          children[index],
        ],
      ],
    );
  }
}
