import 'package:flutter/widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/platform/platform_capabilities.dart';
import 'package:starter/shared/adaptive/app_interaction_policy.dart';
import 'package:starter/shared/adaptive/app_presentation_policy.dart';

part 'gallery_environment.freezed.dart';

enum GallerySystemTextScale { normal, maximumNonlinear }

enum GalleryDisplayFeature { none, verticalFold }

@Freezed(copyWith: false)
class GalleryViewportPreset with _$GalleryViewportPreset {
  const GalleryViewportPreset({
    required this.id,
    required this.size,
    required this.labelBuilder,
    this.devicePixelRatio = 1,
  });

  @override
  final String id;
  @override
  final Size size;
  @override
  final GalleryLabelBuilder labelBuilder;
  @override
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

@Freezed(copyWith: false)
class GalleryEnvironment with _$GalleryEnvironment {
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

  @override
  final GalleryViewportPreset viewport;
  @override
  final Brightness brightness;
  @override
  final AppAccent accent;
  @override
  final AppLocale locale;
  @override
  final double appFontScale;
  @override
  final GallerySystemTextScale systemTextScale;
  @override
  final AppInteractionPolicy interactionPolicy;
  @override
  final AppViewingEnvironment viewingEnvironment;
  @override
  final AppTvPlatform tvPlatform;
  @override
  final bool animationsEnabled;
  @override
  final bool highContrast;
  @override
  final bool boldText;
  @override
  final bool safeAreaEnabled;
  @override
  final bool keyboardInsetsEnabled;
  @override
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
