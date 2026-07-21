import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/onboarding/onboarding_view_data.dart';
import 'package:starter/shared/adaptive/app_layout_class.dart';
import 'package:starter/shared/theme/app_sizes.dart';
import 'package:starter/shared/theme/app_spacing.dart';

class OnboardingSlide extends StatelessWidget {
  const OnboardingSlide({
    required this.data,
    required this.brandLabel,
    required this.layoutClass,
    super.key,
  });

  final OnboardingSlideViewData data;
  final String brandLabel;
  final AppLayoutClass layoutClass;

  @override
  Widget build(BuildContext context) {
    final visual = _OnboardingVisual(data: data, brandLabel: brandLabel);
    final copy = _OnboardingCopy(data: data);

    return SingleChildScrollView(
      key: ValueKey('onboarding-slide-${data.id}'),
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: switch (layoutClass) {
        AppLayoutClass.compact => Column(
          children: [
            visual,
            const SizedBox(height: AppSpacing.xl),
            copy,
          ],
        ),
        AppLayoutClass.medium => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSizes.readingContentMaxWidth),
            child: FCard(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl2),
                child: Column(
                  children: [
                    visual,
                    const SizedBox(height: AppSpacing.xl2),
                    copy,
                  ],
                ),
              ),
            ),
          ),
        ),
        AppLayoutClass.expanded => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSizes.wideContentMaxWidth),
            child: Row(
              children: [
                Expanded(child: visual),
                const SizedBox(width: AppSpacing.xl3),
                Expanded(
                  child: FCard(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl2),
                      child: copy,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      },
    );
  }
}

class _OnboardingVisual extends StatelessWidget {
  const _OnboardingVisual({required this.data, required this.brandLabel});

  final OnboardingSlideViewData data;
  final String brandLabel;

  @override
  Widget build(BuildContext context) {
    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_iconFor(data.visual), size: 72, color: context.theme.colors.primary),
            const SizedBox(height: AppSpacing.lg),
            Text(
              brandLabel,
              textAlign: TextAlign.center,
              style: context.theme.typography.body.lg,
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingCopy extends StatelessWidget {
  const _OnboardingCopy({required this.data});

  final OnboardingSlideViewData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(data.title, style: context.theme.typography.display.xl2),
        const SizedBox(height: AppSpacing.md),
        Text(data.body, style: context.theme.typography.body.lg),
      ],
    );
  }
}

IconData _iconFor(OnboardingVisual visual) => switch (visual) {
  OnboardingVisual.foundation => FLucideIcons.blocks,
  OnboardingVisual.adaptive => FLucideIcons.monitorSmartphone,
  OnboardingVisual.preferences => FLucideIcons.slidersHorizontal,
};
