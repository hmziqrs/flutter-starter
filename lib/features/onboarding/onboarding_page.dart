import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/onboarding/onboarding_slide.dart';
import 'package:starter/features/onboarding/onboarding_view_data.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/adaptive/app_layout_class.dart';
import 'package:starter/shared/adaptive/app_layout_provider.dart';
import 'package:starter/shared/adaptive/app_presentation_policy.dart';
import 'package:starter/shared/motion/app_motion.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/widgets/brand/app_ring_marker.dart';
import 'package:starter/shared/widgets/brand/app_wordmark.dart';

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

class _OnboardingPageState extends State<OnboardingPage> with RestorationMixin {
  final RestorableIntN _restoredPage = RestorableIntN(null);
  late PageController _controller = PageController(initialPage: widget.initialPage);
  late int _page = widget.initialPage;
  AppLayoutClass? _lastLayoutClass;
  bool _restored = false;

  @override
  String get restorationId => 'onboarding-page';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_restoredPage, 'page');
    _restored = true;
    final restored = _restoredPage.value;
    if (restored != null && restored != _page) {
      _page = restored;
      if (_controller.initialPage != restored) {
        _controller.dispose();
        _controller = PageController(initialPage: restored);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _restoredPage.dispose();
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
    final spacing = context.spacing;
    final slides = widget.slides ?? OnboardingFixtures.standard(translations);
    final compact = layoutClass == AppLayoutClass.compact;

    return FScaffold(
      childPad: false,
      child: SafeArea(
        child: Column(
          key: ValueKey('onboarding-layout-${layoutClass.name}'),
          children: [
            // The quiet header: the wordmark (the brand's only logo) on the
            // start side and the skip affordance on the end side. Skip is the
            // least important action on the screen, so it is a plain muted
            // label on the app type scale — never the first thing focused.
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                spacing.xl,
                spacing.sm,
                spacing.sm,
                spacing.sm,
              ),
              child: Row(
                children: [
                  // Header wordmark at the shell's text-lg default (BRAND.md
                  // s7): the same size the expanded shell header carries.
                  AppWordmark(name: translations.app.name),
                  const Spacer(),
                  _QuietSkip(label: translations.common.skip, onPress: widget.onSkip),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                key: const ValueKey('onboarding-pager'),
                controller: _controller,
                itemCount: slides.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) => OnboardingSlide(
                  data: slides[index],
                  layoutClass: layoutClass,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                spacing.xl,
                spacing.md,
                spacing.xl,
                spacing.xl,
              ),
              child: Column(
                children: [
                  Semantics(
                    key: const ValueKey('onboarding-progress'),
                    liveRegion: true,
                    label: translations.onboarding.progress(
                      current: _page + 1,
                      total: slides.length,
                    ),
                    child: _ProgressMarkers(count: slides.length, current: _page),
                  ),
                  SizedBox(height: spacing.lg),
                  if (compact)
                    _CompactActions(
                      back: _page > 0 ? _buildBackButton(translations) : null,
                      continueButton: _buildContinueButton(
                        translations,
                        isLastPage: _page == slides.length - 1,
                      ),
                    )
                  else
                    _WideActions(
                      back: _page > 0 ? _buildBackButton(translations, mainAxisSize: .min) : null,
                      continueButton: _buildContinueButton(
                        translations,
                        isLastPage: _page == slides.length - 1,
                        mainAxisSize: .min,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(Translations translations, {MainAxisSize mainAxisSize = .max}) {
    return FButton(
      key: const ValueKey('onboarding-back'),
      variant: .outline,
      mainAxisSize: mainAxisSize,
      style: _lineOnlyOutline,
      onPress: _previous,
      child: Text(translations.common.back),
    );
  }

  Widget _buildContinueButton(
    Translations translations, {
    required bool isLastPage,
    MainAxisSize mainAxisSize = .max,
  }) {
    // Calm entry (the ask): nothing is focused until the visitor acts, so
    // no focus ring is painted on arrival on pointer surfaces. Ten-foot
    // presentation is the exception — directional focus is the only input
    // there, so the primary action takes the cold focus (the platform rule
    // the shell's TV focus anchors assert).
    final usesDirectionalFocus =
        AppPresentationPolicy.maybeOf(context)?.usesDirectionalFocus ?? false;
    return FButton(
      key: const ValueKey('onboarding-continue'),
      autofocus: usesDirectionalFocus,
      mainAxisSize: mainAxisSize,
      style: _noPressMotion,
      onPress: isLastPage ? widget.onOpenPaywall : _next,
      child: Text(
        isLastPage ? translations.onboarding.openPaywall : translations.common.continueAction,
      ),
    );
  }

  /// Brand motion rule (BRAND.md s10): press feedback is color only, so the
  /// stock press bounce is switched off on every action here.
  static const FButtonStyleDelta _noPressMotion = FButtonStyleDelta.delta(
    tappableStyle: FTappableStyleDelta.delta(motion: FTappableMotion.none),
  );

  /// Brand outline recipe (BRAND.md s9, s13): an outline button is a line at
  /// rest in both modes — no fill. ForUI's inherit fills the outline variant
  /// with the card color, which reads as a grey-filled control in dark mode,
  /// so the rest state's fill is stripped here. Only the base (rest)
  /// decoration is touched: the inherit's own hover and press deltas are
  /// kept, so feedback stays color-only.
  static final FButtonStyleDelta _lineOnlyOutline = FButtonStyleDelta.delta(
    tappableStyle: const FTappableStyleDelta.delta(motion: FTappableMotion.none),
    decoration: FVariantsDelta.delta([
      FVariantOperation.base(const DecorationDelta.shapeDelta(color: null)),
    ]),
  );

  void _next() => _moveTo(_page + 1);

  void _previous() => _moveTo(_page - 1);

  void _onPageChanged(int page) {
    if (_restored) {
      _restoredPage.value = page;
    }
    setState(() => _page = page);
  }

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

/// The skip affordance: muted 14 text on the app type scale, sitting on the
/// md control size (44 on touch), calm but findable. Hover and press stay
/// color-only; nothing here is focused at entry, so no ring is painted
/// until the visitor interacts.
class _QuietSkip extends StatelessWidget {
  const _QuietSkip({required this.label, required this.onPress});

  final String label;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    return FButton(
      key: const ValueKey('onboarding-skip'),
      variant: .ghost,
      mainAxisSize: .min,
      style: const FButtonStyleDelta.delta(
        tappableStyle: FTappableStyleDelta.delta(motion: FTappableMotion.none),
      ),
      onPress: onPress,
      child: Text(
        label,
        style: context.theme.typography.body.sm.copyWith(
          color: context.theme.colors.mutedForeground,
        ),
      ),
    );
  }
}

/// A row of the brand's ring markers (BRAND.md s7): the current page's ring
/// is filled and orange, the rest hollow. The markers carry no meaning on
/// their own — the surrounding live region announces the progress words.
class _ProgressMarkers extends StatelessWidget {
  const _ProgressMarkers({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: spacing.sm),
            child: AppRingMarker(
              filled: i == current,
              color: i == current
                  ? context.theme.colors.primary
                  : context.theme.colors.mutedForeground,
            ),
          ),
      ],
    );
  }
}

/// Compact bottom actions: the primary Continue fills the width and Back
/// (outline) sits above it, equally wide.
class _CompactActions extends StatelessWidget {
  const _CompactActions({required this.back, required this.continueButton});

  final Widget? back;
  final Widget continueButton;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (back != null) ...[
          back!,
          SizedBox(height: context.spacing.sm),
        ],
        continueButton,
      ],
    );
  }
}

/// Wide bottom actions: both buttons right-aligned at their content size,
/// the primary Continue last.
class _WideActions extends StatelessWidget {
  const _WideActions({required this.back, required this.continueButton});

  final Widget? back;
  final Widget continueButton;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (back != null) ...[back!, SizedBox(width: context.spacing.md)],
        continueButton,
      ],
    );
  }
}
