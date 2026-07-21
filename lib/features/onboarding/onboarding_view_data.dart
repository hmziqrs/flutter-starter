import 'package:starter/i18n/translations.g.dart';

enum OnboardingVisual { foundation, adaptive, preferences }

class OnboardingSlideViewData {
  const OnboardingSlideViewData({
    required this.id,
    required this.title,
    required this.body,
    required this.visual,
  });

  final String id;
  final String title;
  final String body;
  final OnboardingVisual visual;
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
