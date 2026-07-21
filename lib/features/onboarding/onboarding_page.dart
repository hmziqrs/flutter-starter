import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/onboarding/onboarding_slide.dart';
import 'package:starter/features/onboarding/onboarding_view_data.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/adaptive/app_layout_class.dart';
import 'package:starter/shared/adaptive/app_layout_provider.dart';
import 'package:starter/shared/motion/app_motion.dart';
import 'package:starter/shared/theme/app_spacing.dart';

class OnboardingPage extends StatefulWidget {
  OnboardingPage({
    required this.onSkip,
    required this.onOpenPaywall,
    this.initialPage = 0,
    List<OnboardingSlideViewData>? slides,
    super.key,
  }) : assert(initialPage >= 0 && initialPage <= 2, 'initialPage must be from 0 through 2.'),
       assert(slides == null || slides.length == 3, 'Onboarding requires exactly three slides.'),
       slides = slides == null ? null : List.unmodifiable(slides);

  final VoidCallback onSkip;
  final VoidCallback onOpenPaywall;
  final int initialPage;
  final List<OnboardingSlideViewData>? slides;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late PageController _controller = PageController(initialPage: widget.initialPage);
  late int _page = widget.initialPage;
  AppLayoutClass? _lastLayoutClass;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppLayoutScope(
      builder: (context, _) => Consumer(
        builder: (context, ref, _) {
          return _buildContent(context, ref.watch(appLayoutClassProvider));
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppLayoutClass layoutClass) {
    _retainPageAcrossLayoutChange(layoutClass);
    final translations = context.t;
    final slides = widget.slides ?? OnboardingFixtures.standard(translations);

    return SafeArea(
      child: Column(
        key: ValueKey('onboarding-layout-${layoutClass.name}'),
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.xl,
              AppSpacing.sm,
              AppSpacing.xl,
              0,
            ),
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FButton(
                key: const ValueKey('onboarding-skip'),
                variant: .ghost,
                mainAxisSize: .min,
                onPress: widget.onSkip,
                child: Text(translations.common.skip),
              ),
            ),
          ),
          Expanded(
            child: PageView.builder(
              key: const ValueKey('onboarding-pager'),
              controller: _controller,
              itemCount: slides.length,
              onPageChanged: (page) => setState(() => _page = page),
              itemBuilder: (context, index) => OnboardingSlide(
                data: slides[index],
                brandLabel: translations.onboarding.brand,
                layoutClass: layoutClass,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            child: Column(
              children: [
                Semantics(
                  liveRegion: true,
                  child: Text(
                    translations.onboarding.progress(current: _page + 1, total: slides.length),
                    key: const ValueKey('onboarding-progress'),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    if (_page > 0)
                      FButton(
                        key: const ValueKey('onboarding-back'),
                        variant: .outline,
                        mainAxisSize: .min,
                        onPress: _previous,
                        child: Text(translations.common.back),
                      )
                    else
                      const Spacer(),
                    if (_page > 0) const Spacer(),
                    FButton(
                      key: const ValueKey('onboarding-continue'),
                      mainAxisSize: .min,
                      onPress: _page == slides.length - 1 ? widget.onOpenPaywall : _next,
                      child: Text(
                        _page == slides.length - 1
                            ? translations.onboarding.openPaywall
                            : translations.common.continueAction,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _next() => _moveTo(_page + 1);

  void _previous() => _moveTo(_page - 1);

  void _moveTo(int page) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpToPage(page);
      return;
    }
    unawaited(
      _controller.animateToPage(
        page,
        duration: AppMotion.standard,
        curve: AppMotion.standardCurve,
      ),
    );
  }

  void _retainPageAcrossLayoutChange(AppLayoutClass layoutClass) {
    if (_lastLayoutClass case final previous? when previous != layoutClass) {
      final previousController = _controller;
      _controller = PageController(initialPage: _page);
      WidgetsBinding.instance.addPostFrameCallback((_) => previousController.dispose());
    }
    _lastLayoutClass = layoutClass;
  }
}
