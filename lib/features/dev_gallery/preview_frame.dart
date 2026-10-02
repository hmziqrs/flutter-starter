import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:starter/app/interaction_policy_controller.dart';
import 'package:starter/app/platform_capabilities_provider.dart';
import 'package:starter/app/presentation/app_presentation_viewport.dart';
import 'package:starter/app/presentation_policy_controller.dart';
import 'package:starter/features/dev_gallery/gallery_environment.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/platform/platform_capabilities.dart';
import 'package:starter/shared/adaptive/app_interaction_policy.dart';
import 'package:starter/shared/adaptive/app_layout_provider.dart';
import 'package:starter/shared/adaptive/app_presentation_policy.dart';
import 'package:starter/shared/adaptive/app_unit.dart';
import 'package:starter/shared/motion/app_motion.dart';
import 'package:starter/shared/theme/forui_theme_factory.dart';

class PreviewFrame extends StatefulWidget {
  const PreviewFrame({
    required this.environment,
    required this.child,
    super.key,
  });

  static const safeAreaPadding = EdgeInsets.fromLTRB(16, 24, 16, 24);
  static const keyboardInsets = EdgeInsets.only(bottom: 320);
  static const verticalFoldWidth = 16.0;

  final GalleryEnvironment environment;
  final Widget child;

  @override
  State<PreviewFrame> createState() => _PreviewFrameState();
}

class _PreviewFrameState extends State<PreviewFrame> {
  final _ForuiThemeMemo _themeMemo = _ForuiThemeMemo();
  final _MaterialThemeMemo _materialThemeMemo = _MaterialThemeMemo();

  @override
  Widget build(BuildContext context) {
    final environment = widget.environment;
    final child = widget.child;
    final size = environment.viewport.size;
    final devicePixelRatio = environment.viewport.devicePixelRatio;
    final unit = AppUnit.fromSize(size, devicePixelRatio: devicePixelRatio);
    final presentationPolicy = AppPresentationPolicy(
      viewingEnvironment: environment.viewingEnvironment,
      interactionPolicy: environment.interactionPolicy,
    );
    final platformCapabilities = PlatformCapabilities(
      platform: switch (environment.tvPlatform) {
        AppTvPlatform.none => 'gallery',
        AppTvPlatform.androidTv => 'android',
        AppTvPlatform.tvOS => 'tvOS',
      },
      isWeb: false,
      tvPlatform: environment.tvPlatform,
    );
    final theme = _themeMemo.build(
      brightness: environment.brightness,
      accent: environment.accent,
      fontScale: environment.appFontScale,
      interactionPolicy: environment.interactionPolicy,
      responsiveFontScale: unit.typographyScale,
      presentationPolicy: presentationPolicy,
    );
    final safeArea = environment.safeAreaEnabled ? PreviewFrame.safeAreaPadding : EdgeInsets.zero;
    final keyboardInsets = environment.keyboardInsetsEnabled
        ? PreviewFrame.keyboardInsets
        : EdgeInsets.zero;
    final displayFeatures = switch (environment.displayFeature) {
      GalleryDisplayFeature.none => const <DisplayFeature>[],
      GalleryDisplayFeature.verticalFold => [
        DisplayFeature(
          bounds: Rect.fromLTWH(
            (size.width - PreviewFrame.verticalFoldWidth) / 2,
            0,
            PreviewFrame.verticalFoldWidth,
            size.height,
          ),
          type: DisplayFeatureType.fold,
          state: DisplayFeatureState.unknown,
        ),
      ],
    };
    final mediaQuery = MediaQuery.of(context).copyWith(
      size: size,
      devicePixelRatio: devicePixelRatio,
      textScaler: environment.textScaler,
      padding: safeArea,
      viewPadding: safeArea,
      viewInsets: keyboardInsets,
      disableAnimations: !environment.animationsEnabled,
      highContrast: environment.highContrast,
      boldText: environment.boldText,
      displayFeatures: displayFeatures,
    );
    final direction = environment.locale == AppLocale.ar ? TextDirection.rtl : TextDirection.ltr;

    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: SingleChildScrollView(
        key: const ValueKey('gallery-preview-horizontal-scroll'),
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          key: const ValueKey('gallery-preview-vertical-scroll'),
          child: SizedBox(
            key: const ValueKey('gallery-preview-viewport'),
            width: size.width,
            height: size.height,
            child: ProviderScope(
              overrides: [
                interactionPolicyOverrideProvider.overrideWithValue(
                  environment.interactionPolicy,
                ),
                platformCapabilitiesProvider.overrideWithValue(
                  platformCapabilities,
                ),
                presentationPolicyOverrideProvider.overrideWithValue(
                  presentationPolicy,
                ),
              ],
              child: MediaQuery(
                data: mediaQuery,
                child: Localizations.override(
                  context: context,
                  locale: environment.locale.flutterLocale,
                  child: Directionality(
                    textDirection: direction,
                    child: AppPresentationScope(
                      policy: presentationPolicy,
                      child: Theme(
                        key: const ValueKey('gallery-preview-material-theme'),
                        data: _materialThemeMemo.build(theme),
                        child: FTheme(
                          key: const ValueKey('gallery-preview-forui-theme'),
                          data: theme,
                          accessibility: presentationPolicy.usesDirectionalFocus
                              ? FAccessibility(
                                  accessibleNavigation: false,
                                  motion: environment.animationsEnabled
                                      ? FAccessibilityMotion.all
                                      : FAccessibilityMotion.disabled,
                                  focusHighlight: true,
                                )
                              : null,
                          motion: FThemeMotion(
                            duration: environment.animationsEnabled
                                ? AppMotion.standard
                                : Duration.zero,
                            curve: AppMotion.standardCurve,
                          ),
                          child: AppPresentationViewport(
                            child: AppLayoutScope(
                              builder: (_, _) => FToaster(
                                child: FTooltipGroup(
                                  child: Navigator(
                                    pages: [
                                      MaterialPage<void>(
                                        key: const ValueKey(
                                          'gallery-preview-root-page',
                                        ),
                                        child: child,
                                      ),
                                    ],
                                    onDidRemovePage: (_) {
                                      throw StateError(
                                        'The gallery preview root page cannot be removed.',
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

typedef _ForuiThemeKey = ({
  Brightness brightness,
  AppAccent accent,
  double fontScale,
  AppInteractionPolicy interactionPolicy,
  double responsiveFontScale,
  AppPresentationPolicy presentationPolicy,
});

final class _ForuiThemeMemo {
  _ForuiThemeKey? _key;
  late FThemeData _theme;

  FThemeData build({
    required Brightness brightness,
    required AppAccent accent,
    required double fontScale,
    required AppInteractionPolicy interactionPolicy,
    required double responsiveFontScale,
    required AppPresentationPolicy presentationPolicy,
  }) {
    final key = (
      brightness: brightness,
      accent: accent,
      fontScale: fontScale,
      interactionPolicy: interactionPolicy,
      responsiveFontScale: responsiveFontScale,
      presentationPolicy: presentationPolicy,
    );
    if (_key == key) {
      return _theme;
    }
    final theme = ForuiThemeFactory.build(
      brightness: brightness,
      accent: accent,
      fontScale: fontScale,
      interactionPolicy: interactionPolicy,
      responsiveFontScale: responsiveFontScale,
      presentationPolicy: presentationPolicy,
    );
    _key = key;
    _theme = theme;
    return theme;
  }
}

final class _MaterialThemeMemo {
  FThemeData? _data;
  late ThemeData _theme;

  ThemeData build(FThemeData data) {
    if (identical(_data, data)) {
      return _theme;
    }
    final theme = data.toApproximateMaterialTheme();
    _data = data;
    _theme = theme;
    return theme;
  }
}
