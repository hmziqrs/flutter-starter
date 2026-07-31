import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:starter/i18n/translations.g.dart';

part 'onboarding_view_data.freezed.dart';

enum OnboardingVisual { foundation, adaptive, preferences }

@freezed
abstract class OnboardingSlideViewData with _$OnboardingSlideViewData {
  const factory OnboardingSlideViewData({
    required String id,
    required String title,
    required String body,
    required OnboardingVisual visual,
  }) = _OnboardingSlideViewData;
}

abstract final class OnboardingSlideIds {
  static const foundation = 'foundation';
  static const adaptive = 'adaptive';
  static const preferences = 'preferences';
}

abstract final class OnboardingFixtures {
  static List<OnboardingSlideViewData> standard(Translations translations) => [
    OnboardingSlideViewData(
      id: OnboardingSlideIds.foundation,
      title: translations.onboarding.firstTitle,
      body: translations.onboarding.firstBody,
      visual: OnboardingVisual.foundation,
    ),
    OnboardingSlideViewData(
      id: OnboardingSlideIds.adaptive,
      title: translations.onboarding.middleTitle,
      body: translations.onboarding.middleBody,
      visual: OnboardingVisual.adaptive,
    ),
    OnboardingSlideViewData(
      id: OnboardingSlideIds.preferences,
      title: translations.onboarding.finalTitle,
      body: translations.onboarding.finalBody,
      visual: OnboardingVisual.preferences,
    ),
  ];
}
