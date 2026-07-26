import 'dart:async';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/features/dev_gallery/gallery_environment.dart';
import 'package:starter/features/dev_gallery/preview_frame.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/adaptive/app_interaction_policy.dart';
import 'package:starter/shared/theme/app_spacing.dart';

class ScreenGalleryPage extends StatefulWidget {
  ScreenGalleryPage({
    required List<GalleryCase> cases,
    this.initialEnvironment,
    super.key,
  }) : cases = List.unmodifiable(cases);

  final List<GalleryCase> cases;
  final GalleryEnvironment? initialEnvironment;

  @override
  State<ScreenGalleryPage> createState() => _ScreenGalleryPageState();
}

class _ScreenGalleryPageState extends State<ScreenGalleryPage> {
  late GalleryEnvironment _environment;
  late AppLocale _previousLocale;
  late String? _selectedScreenId;
  late String? _selectedCaseId;
  Future<void> _localeChanges = Future<void>.value();
  String _query = '';

  GalleryCase? get _selectedCase {
    for (final galleryCase in widget.cases) {
      if (galleryCase.id == _selectedCaseId) return galleryCase;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _previousLocale = LocaleSettings.currentLocale;
    _environment = widget.initialEnvironment ?? GalleryEnvironment.defaults();
    _selectedScreenId = widget.cases.firstOrNull?.screenId;
    _selectedCaseId = widget.cases.firstOrNull?.id;
    _queueLocale(_environment.locale);
  }

  @override
  void didUpdateWidget(covariant ScreenGalleryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedCase == null) {
      _selectedScreenId = widget.cases.firstOrNull?.screenId;
      _selectedCaseId = widget.cases.firstOrNull?.id;
    }
  }

  @override
  void dispose() {
    unawaited(_localeChanges.then((_) => LocaleSettings.setLocale(_previousLocale)));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    return FScaffold(
      childPad: false,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final controls = _GalleryControls(
              cases: widget.cases,
              environment: _environment,
              query: _query,
              selectedScreenId: _selectedScreenId,
              selectedCaseId: _selectedCaseId,
              onQueryChanged: (query) => setState(() => _query = query),
              onScreenSelected: _selectScreen,
              onCaseSelected: (id) => setState(() => _selectedCaseId = id),
              onEnvironmentChanged: _setEnvironment,
              onReset: _resetEnvironment,
            );
            final preview = _GalleryPreview(
              environment: _environment,
              galleryCase: _selectedCase,
            );

            if (constraints.maxWidth < context.theme.breakpoints.lg) {
              final previewHeight = (constraints.maxHeight * 0.52).clamp(320, 640).toDouble();
              return Column(
                key: const ValueKey('gallery-compact-layout'),
                children: [
                  Expanded(
                    child: ListView(
                      key: const ValueKey('gallery-controls-scroll'),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      children: [
                        Text(
                          translations.devGallery.title,
                          style: context.theme.typography.display.xl2,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        controls,
                      ],
                    ),
                  ),
                  SizedBox(
                    height: previewHeight,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: preview,
                    ),
                  ),
                ],
              );
            }

            return Row(
              key: const ValueKey('gallery-expanded-layout'),
              children: [
                SizedBox(
                  width: 360,
                  child: ListView(
                    key: const ValueKey('gallery-controls-scroll'),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      Text(
                        translations.devGallery.title,
                        style: context.theme.typography.display.xl2,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      controls,
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(
                      top: AppSpacing.lg,
                      end: AppSpacing.lg,
                      bottom: AppSpacing.lg,
                    ),
                    child: preview,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _selectScreen(String screenId) {
    final firstCase = widget.cases.firstWhere((galleryCase) => galleryCase.screenId == screenId);
    setState(() {
      _selectedScreenId = screenId;
      _selectedCaseId = firstCase.id;
    });
  }

  void _setEnvironment(GalleryEnvironment environment) {
    setState(() => _environment = environment);
    if (environment.locale != LocaleSettings.currentLocale) {
      _queueLocale(environment.locale);
    }
  }

  void _resetEnvironment() {
    final defaults = GalleryEnvironment.defaults();
    setState(() => _environment = defaults);
    _queueLocale(defaults.locale);
  }

  void _queueLocale(AppLocale locale) {
    _localeChanges = _localeChanges.then((_) async {
      await LocaleSettings.setLocale(locale);
    });
  }
}

class _GalleryPreview extends StatelessWidget {
  const _GalleryPreview({required this.environment, required this.galleryCase});

  final GalleryEnvironment environment;
  final GalleryCase? galleryCase;

  @override
  Widget build(BuildContext context) {
    final galleryCase = this.galleryCase;
    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.t.devGallery.preview, style: context.theme.typography.display.lg),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: PreviewFrame(
                environment: environment,
                child: galleryCase == null
                    ? Center(child: Text(context.t.devGallery.caseNotFound))
                    : Builder(builder: galleryCase.build),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GalleryControls extends StatelessWidget {
  const _GalleryControls({
    required this.cases,
    required this.environment,
    required this.query,
    required this.selectedScreenId,
    required this.selectedCaseId,
    required this.onQueryChanged,
    required this.onScreenSelected,
    required this.onCaseSelected,
    required this.onEnvironmentChanged,
    required this.onReset,
  });

  final List<GalleryCase> cases;
  final GalleryEnvironment environment;
  final String query;
  final String? selectedScreenId;
  final String? selectedCaseId;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onScreenSelected;
  final ValueChanged<String> onCaseSelected;
  final ValueChanged<GalleryEnvironment> onEnvironmentChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    final gallery = translations.devGallery;
    final normalizedQuery = query.trim().toLowerCase();
    final matchingCases = cases
        .where((galleryCase) {
          if (normalizedQuery.isEmpty) return true;
          return galleryCase.screenLabel(translations).toLowerCase().contains(normalizedQuery) ||
              galleryCase.caseLabel(translations).toLowerCase().contains(normalizedQuery);
        })
        .toList(growable: false);
    final screenIds = <String>[];
    for (final galleryCase in matchingCases) {
      if (!screenIds.contains(galleryCase.screenId)) screenIds.add(galleryCase.screenId);
    }
    final visibleCases = matchingCases
        .where((galleryCase) => galleryCase.screenId == selectedScreenId)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FTextField(
          key: const ValueKey('gallery-search'),
          label: Text(gallery.search),
          control: .managed(onChange: (value) => onQueryChanged(value.text)),
        ),
        const SizedBox(height: AppSpacing.lg),
        _ControlGroup(
          title: gallery.screen,
          children: [
            for (final screenId in screenIds)
              _ChoiceButton(
                buttonKey: ValueKey('gallery-screen-$screenId'),
                label: matchingCases
                    .firstWhere((galleryCase) => galleryCase.screenId == screenId)
                    .screenLabel(translations),
                selected: screenId == selectedScreenId,
                onPress: () => onScreenSelected(screenId),
              ),
          ],
        ),
        _ControlGroup(
          title: gallery.galleryCase,
          emptyLabel: gallery.caseNotFound,
          children: [
            for (final galleryCase in visibleCases)
              _ChoiceButton(
                buttonKey: ValueKey('gallery-case-${galleryCase.id}'),
                label: galleryCase.caseLabel(translations),
                selected: galleryCase.id == selectedCaseId,
                onPress: () => onCaseSelected(galleryCase.id),
              ),
          ],
        ),
        _ControlGroup(
          title: gallery.viewport,
          children: [
            for (final preset in GalleryViewportPresets.values)
              _ChoiceButton(
                buttonKey: ValueKey('gallery-viewport-${preset.id}'),
                label: preset.label(translations),
                selected: preset.id == environment.viewport.id,
                onPress: () => onEnvironmentChanged(environment.copyWith(viewport: preset)),
              ),
          ],
        ),
        _ControlGroup(
          title: gallery.theme,
          children: [
            _ChoiceButton(
              buttonKey: const ValueKey('gallery-theme-light'),
              label: gallery.light,
              selected: environment.brightness == Brightness.light,
              onPress: () =>
                  onEnvironmentChanged(environment.copyWith(brightness: Brightness.light)),
            ),
            _ChoiceButton(
              buttonKey: const ValueKey('gallery-theme-dark'),
              label: gallery.dark,
              selected: environment.brightness == Brightness.dark,
              onPress: () =>
                  onEnvironmentChanged(environment.copyWith(brightness: Brightness.dark)),
            ),
          ],
        ),
        _ControlGroup(
          title: gallery.accent,
          children: [
            for (final accent in AppAccent.values)
              _ChoiceButton(
                buttonKey: ValueKey('gallery-accent-${accent.name}'),
                label: _accentLabel(translations, accent),
                selected: environment.accent == accent,
                onPress: () => onEnvironmentChanged(environment.copyWith(accent: accent)),
              ),
          ],
        ),
        _ControlGroup(
          title: gallery.locale,
          children: [
            for (final locale in AppLocale.values)
              _ChoiceButton(
                buttonKey: ValueKey('gallery-locale-${locale.name}'),
                label: _localeLabel(translations, locale),
                selected: environment.locale == locale,
                onPress: () => onEnvironmentChanged(environment.copyWith(locale: locale)),
              ),
          ],
        ),
        _ControlGroup(
          title: gallery.textScale,
          children: [
            for (final scale in const [0.85, 1.0, 1.6])
              _ChoiceButton(
                buttonKey: ValueKey('gallery-font-scale-${(scale * 100).round()}'),
                label: NumberFormat.percentPattern(environment.locale.languageTag).format(scale),
                selected: environment.appFontScale == scale,
                onPress: () => onEnvironmentChanged(environment.copyWith(appFontScale: scale)),
              ),
          ],
        ),
        _ControlGroup(
          title: gallery.systemTextScale,
          children: [
            _ChoiceButton(
              buttonKey: const ValueKey('gallery-system-scale-normal'),
              label: gallery.normal,
              selected: environment.systemTextScale == GallerySystemTextScale.normal,
              onPress: () => onEnvironmentChanged(
                environment.copyWith(systemTextScale: GallerySystemTextScale.normal),
              ),
            ),
            _ChoiceButton(
              buttonKey: const ValueKey('gallery-system-scale-maximumNonlinear'),
              label: gallery.maximum,
              selected: environment.systemTextScale == GallerySystemTextScale.maximumNonlinear,
              onPress: () => onEnvironmentChanged(
                environment.copyWith(systemTextScale: GallerySystemTextScale.maximumNonlinear),
              ),
            ),
          ],
        ),
        _ControlGroup(
          title: gallery.interaction,
          children: [
            for (final policy in AppInteractionPolicy.values)
              _ChoiceButton(
                buttonKey: ValueKey('gallery-interaction-${policy.name}'),
                label: _interactionLabel(translations, policy),
                selected: environment.interactionPolicy == policy,
                onPress: () =>
                    onEnvironmentChanged(environment.copyWith(interactionPolicy: policy)),
              ),
          ],
        ),
        _BooleanControl(
          id: 'animations',
          title: gallery.motion,
          value: environment.animationsEnabled,
          onChanged: (value) =>
              onEnvironmentChanged(environment.copyWith(animationsEnabled: value)),
        ),
        _BooleanControl(
          id: 'high-contrast',
          title: gallery.highContrast,
          value: environment.highContrast,
          onChanged: (value) => onEnvironmentChanged(environment.copyWith(highContrast: value)),
        ),
        _BooleanControl(
          id: 'bold-text',
          title: gallery.boldText,
          value: environment.boldText,
          onChanged: (value) => onEnvironmentChanged(environment.copyWith(boldText: value)),
        ),
        _BooleanControl(
          id: 'safe-area',
          title: gallery.safeArea,
          value: environment.safeAreaEnabled,
          onChanged: (value) => onEnvironmentChanged(environment.copyWith(safeAreaEnabled: value)),
        ),
        _BooleanControl(
          id: 'keyboard-insets',
          title: gallery.keyboardInsets,
          value: environment.keyboardInsetsEnabled,
          onChanged: (value) =>
              onEnvironmentChanged(environment.copyWith(keyboardInsetsEnabled: value)),
        ),
        _ControlGroup(
          title: gallery.displayFeature,
          children: [
            _ChoiceButton(
              buttonKey: const ValueKey('gallery-display-none'),
              label: gallery.none,
              selected: environment.displayFeature == GalleryDisplayFeature.none,
              onPress: () => onEnvironmentChanged(
                environment.copyWith(displayFeature: GalleryDisplayFeature.none),
              ),
            ),
            _ChoiceButton(
              buttonKey: const ValueKey('gallery-display-verticalFold'),
              label: gallery.fold,
              selected: environment.displayFeature == GalleryDisplayFeature.verticalFold,
              onPress: () => onEnvironmentChanged(
                environment.copyWith(displayFeature: GalleryDisplayFeature.verticalFold),
              ),
            ),
          ],
        ),
        FButton(
          key: const ValueKey('gallery-reset-controls'),
          variant: .outline,
          builder: (_, _, _, _, _, child) => Flexible(child: child!),
          onPress: onReset,
          child: Text(gallery.resetControls),
        ),
      ],
    );
  }
}

class _BooleanControl extends StatelessWidget {
  const _BooleanControl({
    required this.id,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String id;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final gallery = context.t.devGallery;
    return _ControlGroup(
      title: title,
      children: [
        _ChoiceButton(
          buttonKey: ValueKey('gallery-$id-enabled'),
          label: gallery.enabled,
          selected: value,
          onPress: () => onChanged(true),
        ),
        _ChoiceButton(
          buttonKey: ValueKey('gallery-$id-disabled'),
          label: gallery.disabled,
          selected: !value,
          onPress: () => onChanged(false),
        ),
      ],
    );
  }
}

class _ControlGroup extends StatelessWidget {
  const _ControlGroup({required this.title, required this.children, this.emptyLabel});

  final String title;
  final List<Widget> children;
  final String? emptyLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: context.theme.typography.display.sm),
          const SizedBox(height: AppSpacing.sm),
          if (children.isEmpty)
            Text(emptyLabel ?? context.t.devGallery.caseNotFound)
          else
            Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: children),
        ],
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.buttonKey,
    required this.label,
    required this.selected,
    required this.onPress,
  });

  final Key buttonKey;
  final String label;
  final bool selected;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    return FButton(
      key: buttonKey,
      variant: selected ? .primary : .outline,
      size: .sm,
      mainAxisSize: .min,
      selected: selected,
      builder: (_, _, _, _, _, child) => Flexible(child: child!),
      onPress: onPress,
      child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis),
    );
  }
}

String _accentLabel(Translations translations, AppAccent accent) {
  return switch (accent) {
    AppAccent.neutral => translations.settings.accentNeutral,
    AppAccent.green => translations.settings.accentGreen,
    AppAccent.blue => translations.settings.accentBlue,
    AppAccent.amber => translations.settings.accentAmber,
    AppAccent.rose => translations.settings.accentRose,
    AppAccent.violet => translations.settings.accentViolet,
  };
}

String _localeLabel(Translations translations, AppLocale locale) {
  return switch (locale) {
    AppLocale.en => translations.settings.languageEnglish,
    AppLocale.ar => translations.settings.languageArabic,
    AppLocale.zhHans => translations.settings.languageChinese,
  };
}

String _interactionLabel(Translations translations, AppInteractionPolicy policy) {
  return switch (policy) {
    AppInteractionPolicy.touch => translations.devGallery.touch,
    AppInteractionPolicy.precisionPointer => translations.devGallery.precision,
    AppInteractionPolicy.hybrid => translations.devGallery.hybrid,
  };
}
