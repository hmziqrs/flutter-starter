import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/adaptive/app_interaction_policy.dart';
import 'package:starter/shared/adaptive/app_presentation_policy.dart';
import 'package:starter/shared/motion/app_motion.dart';
import 'package:starter/shared/theme/app_sizes.dart';

@immutable
final class AppPresentationTokens extends ThemeExtension<AppPresentationTokens> {
  const AppPresentationTokens({
    required this.safeContentFraction,
    required this.formContentMaxWidth,
    required this.readingContentMaxWidth,
    required this.wideContentMaxWidth,
    required this.bodyTypeScale,
    required this.displayTypeScale,
    required this.spacingScale,
    required this.controlMinHeight,
    required this.focusTargetMinSize,
    required this.cardPadding,
    required this.cardGap,
    required this.navigationWidth,
    required this.focusOutlineWidth,
    required this.focusColor,
    required this.focusSpacing,
    required this.focusElevation,
    required this.focusScale,
    required this.scrollRevealPadding,
    required this.overlayMaxWidth,
    required this.overlayEdgeMargin,
    required this.focusTransitionDuration,
  });

  factory AppPresentationTokens.resolve({
    required AppPresentationPolicy policy,
    required Color focusColor,
  }) {
    if (!policy.isTenFoot) {
      final minimumControlSize = policy.interactionPolicy == AppInteractionPolicy.precisionPointer
          ? 36.0
          : 44.0;
      return AppPresentationTokens(
        safeContentFraction: 0,
        formContentMaxWidth: AppSizes.formContentMaxWidth,
        readingContentMaxWidth: AppSizes.readingContentMaxWidth,
        wideContentMaxWidth: AppSizes.wideContentMaxWidth,
        bodyTypeScale: 1,
        displayTypeScale: 1,
        spacingScale: 1,
        controlMinHeight: minimumControlSize,
        focusTargetMinSize: minimumControlSize,
        cardPadding: 24,
        cardGap: 16,
        navigationWidth: AppSizes.expandedSidebarWidth,
        focusOutlineWidth: 2,
        focusColor: focusColor,
        focusSpacing: 2,
        focusElevation: 0,
        focusScale: 1,
        scrollRevealPadding: 16,
        overlayMaxWidth: 560,
        overlayEdgeMargin: 24,
        focusTransitionDuration: AppMotion.quick,
      );
    }

    return AppPresentationTokens(
      safeContentFraction: 0.05,
      formContentMaxWidth: 680,
      readingContentMaxWidth: 960,
      wideContentMaxWidth: 1440,
      bodyTypeScale: 1.35,
      displayTypeScale: 1.3,
      spacingScale: 1.3,
      controlMinHeight: 66,
      focusTargetMinSize: 66,
      cardPadding: 32,
      cardGap: 24,
      navigationWidth: 320,
      focusOutlineWidth: 3,
      focusColor: focusColor,
      focusSpacing: 4,
      focusElevation: 10,
      focusScale: 1.035,
      scrollRevealPadding: 32,
      overlayMaxWidth: 760,
      overlayEdgeMargin: 40,
      focusTransitionDuration: AppMotion.quick,
    );
  }

  final double safeContentFraction;
  final double formContentMaxWidth;
  final double readingContentMaxWidth;
  final double wideContentMaxWidth;
  final double bodyTypeScale;
  final double displayTypeScale;
  final double spacingScale;
  final double controlMinHeight;
  final double focusTargetMinSize;
  final double cardPadding;
  final double cardGap;
  final double navigationWidth;
  final double focusOutlineWidth;
  final Color focusColor;
  final double focusSpacing;
  final double focusElevation;
  final double focusScale;
  final double scrollRevealPadding;
  final double overlayMaxWidth;
  final double overlayEdgeMargin;
  final Duration focusTransitionDuration;

  @override
  AppPresentationTokens copyWith({
    double? safeContentFraction,
    double? formContentMaxWidth,
    double? readingContentMaxWidth,
    double? wideContentMaxWidth,
    double? bodyTypeScale,
    double? displayTypeScale,
    double? spacingScale,
    double? controlMinHeight,
    double? focusTargetMinSize,
    double? cardPadding,
    double? cardGap,
    double? navigationWidth,
    double? focusOutlineWidth,
    Color? focusColor,
    double? focusSpacing,
    double? focusElevation,
    double? focusScale,
    double? scrollRevealPadding,
    double? overlayMaxWidth,
    double? overlayEdgeMargin,
    Duration? focusTransitionDuration,
  }) {
    return AppPresentationTokens(
      safeContentFraction: safeContentFraction ?? this.safeContentFraction,
      formContentMaxWidth: formContentMaxWidth ?? this.formContentMaxWidth,
      readingContentMaxWidth: readingContentMaxWidth ?? this.readingContentMaxWidth,
      wideContentMaxWidth: wideContentMaxWidth ?? this.wideContentMaxWidth,
      bodyTypeScale: bodyTypeScale ?? this.bodyTypeScale,
      displayTypeScale: displayTypeScale ?? this.displayTypeScale,
      spacingScale: spacingScale ?? this.spacingScale,
      controlMinHeight: controlMinHeight ?? this.controlMinHeight,
      focusTargetMinSize: focusTargetMinSize ?? this.focusTargetMinSize,
      cardPadding: cardPadding ?? this.cardPadding,
      cardGap: cardGap ?? this.cardGap,
      navigationWidth: navigationWidth ?? this.navigationWidth,
      focusOutlineWidth: focusOutlineWidth ?? this.focusOutlineWidth,
      focusColor: focusColor ?? this.focusColor,
      focusSpacing: focusSpacing ?? this.focusSpacing,
      focusElevation: focusElevation ?? this.focusElevation,
      focusScale: focusScale ?? this.focusScale,
      scrollRevealPadding: scrollRevealPadding ?? this.scrollRevealPadding,
      overlayMaxWidth: overlayMaxWidth ?? this.overlayMaxWidth,
      overlayEdgeMargin: overlayEdgeMargin ?? this.overlayEdgeMargin,
      focusTransitionDuration: focusTransitionDuration ?? this.focusTransitionDuration,
    );
  }

  @override
  AppPresentationTokens lerp(
    covariant AppPresentationTokens? other,
    double t,
  ) {
    if (other == null) {
      return this;
    }

    return AppPresentationTokens(
      safeContentFraction: _lerp(safeContentFraction, other.safeContentFraction, t),
      formContentMaxWidth: _lerp(formContentMaxWidth, other.formContentMaxWidth, t),
      readingContentMaxWidth: _lerp(readingContentMaxWidth, other.readingContentMaxWidth, t),
      wideContentMaxWidth: _lerp(wideContentMaxWidth, other.wideContentMaxWidth, t),
      bodyTypeScale: _lerp(bodyTypeScale, other.bodyTypeScale, t),
      displayTypeScale: _lerp(displayTypeScale, other.displayTypeScale, t),
      spacingScale: _lerp(spacingScale, other.spacingScale, t),
      controlMinHeight: _lerp(controlMinHeight, other.controlMinHeight, t),
      focusTargetMinSize: _lerp(focusTargetMinSize, other.focusTargetMinSize, t),
      cardPadding: _lerp(cardPadding, other.cardPadding, t),
      cardGap: _lerp(cardGap, other.cardGap, t),
      navigationWidth: _lerp(navigationWidth, other.navigationWidth, t),
      focusOutlineWidth: _lerp(focusOutlineWidth, other.focusOutlineWidth, t),
      focusColor: Color.lerp(focusColor, other.focusColor, t)!,
      focusSpacing: _lerp(focusSpacing, other.focusSpacing, t),
      focusElevation: _lerp(focusElevation, other.focusElevation, t),
      focusScale: _lerp(focusScale, other.focusScale, t),
      scrollRevealPadding: _lerp(scrollRevealPadding, other.scrollRevealPadding, t),
      overlayMaxWidth: _lerp(overlayMaxWidth, other.overlayMaxWidth, t),
      overlayEdgeMargin: _lerp(overlayEdgeMargin, other.overlayEdgeMargin, t),
      focusTransitionDuration: t < 0.5 ? focusTransitionDuration : other.focusTransitionDuration,
    );
  }
}

double _lerp(double a, double b, double t) => lerpDouble(a, b, t)!;

extension AppPresentationTokensBuildContext on BuildContext {
  AppPresentationTokens get presentationTokens {
    for (final extension in theme.extensions) {
      if (extension is AppPresentationTokens) {
        return extension;
      }
    }

    return AppPresentationTokens.resolve(
      policy: const AppPresentationPolicy(
        viewingEnvironment: AppViewingEnvironment.nearField,
        interactionPolicy: AppInteractionPolicy.touch,
      ),
      focusColor: theme.colors.primary,
    );
  }
}
