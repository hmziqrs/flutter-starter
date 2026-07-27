import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:starter/app/interaction_policy_controller.dart';
import 'package:starter/app/platform_capabilities_provider.dart';
import 'package:starter/app/presentation/app_presentation_viewport.dart';
import 'package:starter/app/presentation_policy_controller.dart';
import 'package:starter/features/dev_gallery/gallery_environment.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/platform/platform_capabilities.dart';
import 'package:starter/shared/adaptive/app_layout_provider.dart';
import 'package:starter/shared/adaptive/app_presentation_policy.dart';
import 'package:starter/shared/adaptive/app_unit.dart';
import 'package:starter/shared/motion/app_motion.dart';
import 'package:starter/shared/theme/forui_theme_factory.dart';

class PreviewFrame extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
    final theme = ForuiThemeFactory.build(
      brightness: environment.brightness,
      accent: environment.accent,
      fontScale: environment.appFontScale,
      interactionPolicy: environment.interactionPolicy,
      responsiveFontScale: unit.typographyScale,
      presentationPolicy: presentationPolicy,
    );
    final safeArea = environment.safeAreaEnabled ? safeAreaPadding : EdgeInsets.zero;
    final keyboardInsets = environment.keyboardInsetsEnabled
        ? PreviewFrame.keyboardInsets
        : EdgeInsets.zero;
    final displayFeatures = switch (environment.displayFeature) {
      GalleryDisplayFeature.none => const <DisplayFeature>[],
      GalleryDisplayFeature.verticalFold => [
        DisplayFeature(
          bounds: Rect.fromLTWH(
            (size.width - verticalFoldWidth) / 2,
            0,
            verticalFoldWidth,
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
                        data: theme.toApproximateMaterialTheme(),
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
