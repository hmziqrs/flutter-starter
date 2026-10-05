import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/onboarding/onboarding_view_data.dart';
import 'package:starter/shared/adaptive/app_layout_class.dart';
import 'package:starter/shared/theme/app_presentation_tokens.dart';
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
    final spacing = context.spacing;
    final tokens = context.presentationTokens;

    return SingleChildScrollView(
      key: ValueKey('onboarding-slide-${data.id}'),
      padding: EdgeInsetsDirectional.fromSTEB(
        spacing.xl,
        spacing.lg,
        spacing.xl,
        spacing.xl,
      ),
      child: switch (layoutClass) {
        AppLayoutClass.compact => Column(
          children: [
            visual,
            SizedBox(height: spacing.xl),
            copy,
          ],
        ),
        AppLayoutClass.medium => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: tokens.readingContentMaxWidth,
            ),
            child: FCard(
              child: Padding(
                padding: EdgeInsets.all(spacing.xl2),
                child: Column(
                  children: [
                    visual,
                    SizedBox(height: spacing.xl2),
                    copy,
                  ],
                ),
              ),
            ),
          ),
        ),
        AppLayoutClass.expanded => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: tokens.wideContentMaxWidth),
            child: Row(
              children: [
                Expanded(child: visual),
                SizedBox(width: spacing.xl3),
                Expanded(
                  child: FCard(
                    child: Padding(
                      padding: EdgeInsets.all(spacing.xl2),
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
        padding: EdgeInsets.all(context.spacing.xl2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_iconFor(data.visual), size: 72, color: context.theme.colors.primary),
            SizedBox(height: context.spacing.lg),
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
        SizedBox(height: context.spacing.md),
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
