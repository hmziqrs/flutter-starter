import 'package:flutter/widgets.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/platform/platform_capabilities.dart';
import 'package:starter/shared/adaptive/app_interaction_policy.dart';
import 'package:starter/shared/adaptive/app_presentation_policy.dart';

enum GallerySystemTextScale { normal, maximumNonlinear }

enum GalleryDisplayFeature { none, verticalFold }

@immutable
final class GalleryViewportPreset {
  const GalleryViewportPreset({
    required this.id,
    required this.size,
    required this.labelBuilder,
    this.devicePixelRatio = 1,
  });

  final String id;
  final Size size;
  final GalleryLabelBuilder labelBuilder;
  final double devicePixelRatio;

  String label(Translations translations) => labelBuilder(translations);
}

abstract final class GalleryViewportPresets {
  static final values = <GalleryViewportPreset>[
    GalleryViewportPreset(
      id: 'compact-phone',
      size: const Size(390, 844),
      labelBuilder: (translations) => translations.devGallery.viewportCompactPhone,
    ),
    GalleryViewportPreset(
      id: 'short-phone',
      size: const Size(844, 390),
      labelBuilder: (translations) => translations.devGallery.viewportShortPhone,
    ),
    GalleryViewportPreset(
      id: 'below-medium',
      size: const Size(639, 900),
      labelBuilder: (translations) => translations.devGallery.viewportBelowMedium,
    ),
    GalleryViewportPreset(
      id: 'at-medium',
      size: const Size(640, 900),
      labelBuilder: (translations) => translations.devGallery.viewportAtMedium,
    ),
    GalleryViewportPreset(
      id: 'medium',
      size: const Size(800, 1000),
      labelBuilder: (translations) => translations.devGallery.viewportMedium,
    ),
    GalleryViewportPreset(
      id: 'below-expanded',
      size: const Size(1023, 768),
      labelBuilder: (translations) => translations.devGallery.viewportBelowExpanded,
    ),
    GalleryViewportPreset(
      id: 'at-expanded',
      size: const Size(1024, 768),
      labelBuilder: (translations) => translations.devGallery.viewportAtExpanded,
    ),
    GalleryViewportPreset(
      id: 'desktop',
      size: const Size(1440, 900),
      labelBuilder: (translations) => translations.devGallery.viewportDesktop,
    ),
    GalleryViewportPreset(
      id: 'narrow-desktop',
      size: const Size(700, 700),
      labelBuilder: (translations) => translations.devGallery.viewportNarrowDesktop,
    ),
    GalleryViewportPreset(
      id: 'tv-720p',
      size: const Size(1280, 720),
      labelBuilder: (translations) => translations.devGallery.viewportTv720p,
    ),
    GalleryViewportPreset(
      id: 'tv-1080p',
      size: const Size(1920, 1080),
      labelBuilder: (translations) => translations.devGallery.viewportTv1080p,
    ),
    GalleryViewportPreset(
      id: 'tv-4k-equivalent',
      size: const Size(1920, 1080),
      devicePixelRatio: 2,
      labelBuilder: (translations) => translations.devGallery.viewportTv4k,
    ),
  ];

  static GalleryViewportPreset byId(String id) {
    return values.firstWhere((preset) => preset.id == id);
  }
}

@immutable
final class GalleryEnvironment {
  const GalleryEnvironment({
    required this.viewport,
    required this.brightness,
    required this.accent,
    required this.locale,
    required this.appFontScale,
    required this.systemTextScale,
    required this.interactionPolicy,
    required this.viewingEnvironment,
    required this.tvPlatform,
    required this.animationsEnabled,
    required this.highContrast,
    required this.boldText,
    required this.safeAreaEnabled,
    required this.keyboardInsetsEnabled,
    required this.displayFeature,
  });

  GalleryEnvironment.defaults()
    : viewport = GalleryViewportPresets.values.first,
      brightness = Brightness.light,
      accent = AppAccent.neutral,
      locale = AppLocale.en,
      appFontScale = 1,
      systemTextScale = GallerySystemTextScale.normal,
      interactionPolicy = AppInteractionPolicy.touch,
      viewingEnvironment = AppViewingEnvironment.nearField,
      tvPlatform = AppTvPlatform.none,
      animationsEnabled = true,
      highContrast = false,
      boldText = false,
      safeAreaEnabled = false,
      keyboardInsetsEnabled = false,
      displayFeature = GalleryDisplayFeature.none;

  final GalleryViewportPreset viewport;
  final Brightness brightness;
  final AppAccent accent;
  final AppLocale locale;
  final double appFontScale;
  final GallerySystemTextScale systemTextScale;
  final AppInteractionPolicy interactionPolicy;
  final AppViewingEnvironment viewingEnvironment;
  final AppTvPlatform tvPlatform;
  final bool animationsEnabled;
  final bool highContrast;
  final bool boldText;
  final bool safeAreaEnabled;
  final bool keyboardInsetsEnabled;
  final GalleryDisplayFeature displayFeature;

  TextScaler get textScaler => switch (systemTextScale) {
    GallerySystemTextScale.normal => TextScaler.noScaling,
    GallerySystemTextScale.maximumNonlinear => const GalleryMaximumTextScaler(),
  };

  GalleryEnvironment copyWith({
    GalleryViewportPreset? viewport,
    Brightness? brightness,
    AppAccent? accent,
    AppLocale? locale,
    double? appFontScale,
    GallerySystemTextScale? systemTextScale,
    AppInteractionPolicy? interactionPolicy,
    AppViewingEnvironment? viewingEnvironment,
    AppTvPlatform? tvPlatform,
    bool? animationsEnabled,
    bool? highContrast,
    bool? boldText,
    bool? safeAreaEnabled,
    bool? keyboardInsetsEnabled,
    GalleryDisplayFeature? displayFeature,
  }) {
    return GalleryEnvironment(
      viewport: viewport ?? this.viewport,
      brightness: brightness ?? this.brightness,
      accent: accent ?? this.accent,
      locale: locale ?? this.locale,
      appFontScale: appFontScale ?? this.appFontScale,
      systemTextScale: systemTextScale ?? this.systemTextScale,
      interactionPolicy: interactionPolicy ?? this.interactionPolicy,
      viewingEnvironment: viewingEnvironment ?? this.viewingEnvironment,
      tvPlatform: tvPlatform ?? this.tvPlatform,
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
      highContrast: highContrast ?? this.highContrast,
      boldText: boldText ?? this.boldText,
      safeAreaEnabled: safeAreaEnabled ?? this.safeAreaEnabled,
      keyboardInsetsEnabled: keyboardInsetsEnabled ?? this.keyboardInsetsEnabled,
      displayFeature: displayFeature ?? this.displayFeature,
    );
  }
}

/// A deterministic nonlinear approximation of the platform's maximum text scale.
final class GalleryMaximumTextScaler extends TextScaler {
  const GalleryMaximumTextScaler();

  @override
  double scale(double fontSize) {
    assert(fontSize >= 0, 'fontSize must not be negative.');
    assert(fontSize.isFinite, 'fontSize must be finite.');
    final factor = switch (fontSize) {
      <= 14 => 2,
      <= 20 => 1.85,
      _ => 1.65,
    };
    return fontSize * factor;
  }

  @override
  double get textScaleFactor => 2;
}
