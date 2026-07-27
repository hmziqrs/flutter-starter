import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/app/dependencies.dart';
import 'package:starter/app/platform_capabilities_provider.dart';
import 'package:starter/app/presentation_policy_controller.dart';
import 'package:starter/features/dev_gallery/gallery_environment.dart';
import 'package:starter/shared/adaptive/app_interaction_policy.dart';
import 'package:starter/shared/adaptive/app_presentation_policy.dart';
import 'package:starter/shared/theme/app_presentation_tokens.dart';

import 'tv_test_harness.dart';

void main() {
  testWidgets('injected TV capability resolves one coherent ten-foot remote policy', (
    tester,
  ) async {
    configureTvTestView(tester, size: const Size(500, 700));
    final dependencies = AppDependencies.inMemory(
      platformCapabilities: androidTvCapabilities,
    );

    await pumpTvPresentationHarness(
      tester,
      capabilities: dependencies.platformCapabilities,
      child: const _PolicyProbe(),
    );

    final probeContext = tester.element(find.byKey(tvTestProbeKey));
    final container = ProviderScope.containerOf(probeContext);
    final providerPolicy = container.read(presentationPolicyProvider);

    expect(dependencies.platformCapabilities, androidTvCapabilities);
    expect(
      container.read(platformCapabilitiesProvider),
      androidTvCapabilities,
    );
    expect(
      providerPolicy,
      const AppPresentationPolicy(
        viewingEnvironment: AppViewingEnvironment.tenFoot,
        interactionPolicy: AppInteractionPolicy.remote,
      ),
    );
    expect(AppPresentationPolicy.of(probeContext), providerPolicy);
    expect(FAccessibilityScope.focusHighlightOf(probeContext), isTrue);
    expect(
      find.byKey(const ValueKey('app-presentation-tv-safe-frame')),
      findsOneWidget,
      reason: 'TV presentation must not depend on the narrow test width.',
    );

    final tokens = probeContext.presentationTokens;
    expect(tokens.safeContentFraction, 0.05);
    expect(tokens.controlMinHeight, greaterThanOrEqualTo(66));
    expect(tokens.focusTargetMinSize, greaterThanOrEqualTo(66));
    expect(tokens.focusOutlineWidth, greaterThanOrEqualTo(3));
    expect(tokens.focusScale, greaterThan(1));
  });

  testWidgets('ten-foot safe frame uses per-side maxima and preserves inner signals', (
    tester,
  ) async {
    const size = Size(1920, 1080);
    const viewPadding = EdgeInsets.fromLTRB(120, 20, 50, 80);
    const viewInsets = EdgeInsets.only(bottom: 320);
    const displayFeature = DisplayFeature(
      bounds: Rect.fromLTWH(952, 0, 16, 1080),
      type: DisplayFeatureType.fold,
      state: DisplayFeatureState.unknown,
    );
    configureTvTestView(tester);

    await pumpTvPresentationHarness(
      tester,
      capabilities: androidTvCapabilities,
      policyOverride: tvRemotePolicy,
      mediaQueryData: const MediaQueryData(
        size: size,
        padding: viewPadding,
        viewPadding: viewPadding,
        viewInsets: viewInsets,
        displayFeatures: [displayFeature],
      ),
      child: const ColoredBox(
        key: tvTestProbeKey,
        color: Colors.transparent,
        child: SizedBox.expand(),
      ),
    );

    final safeFrame = tester.widget<Padding>(
      find.byKey(const ValueKey('app-presentation-tv-safe-frame')),
    );
    expect(
      safeFrame.padding,
      const EdgeInsets.fromLTRB(120, 54, 96, 80),
      reason: 'Each edge uses max(viewPadding, 5% axis extent), never their sum.',
    );

    final outerContext = tester.element(
      find.byKey(const ValueKey('app-presentation-tv-safe-frame')),
    );
    final innerContext = tester.element(find.byKey(tvTestProbeKey));
    final outer = MediaQuery.of(outerContext);
    final inner = MediaQuery.of(innerContext);

    expect(outer.padding, viewPadding);
    expect(outer.viewPadding, viewPadding);
    expect(inner.padding, EdgeInsets.zero);
    expect(inner.viewPadding, EdgeInsets.zero);
    expect(inner.viewInsets, viewInsets);
    expect(inner.displayFeatures, const [displayFeature]);
    expect(inner.size, size);
    expect(inner.devicePixelRatio, 1);
    expect(
      tester.getRect(find.byKey(tvTestProbeKey)),
      const Rect.fromLTRB(120, 54, 1824, 1000),
    );
  });

  testWidgets('near-field viewport leaves MediaQuery and geometry unchanged', (
    tester,
  ) async {
    const size = Size(390, 844);
    const padding = EdgeInsets.fromLTRB(7, 11, 13, 17);
    const viewInsets = EdgeInsets.only(bottom: 210);
    configureTvTestView(tester, size: size);

    await pumpTvPresentationHarness(
      tester,
      capabilities: nonTelevisionCapabilities,
      policyOverride: nearFieldTouchPolicy,
      mediaQueryData: const MediaQueryData(
        size: size,
        padding: padding,
        viewPadding: padding,
        viewInsets: viewInsets,
      ),
      child: const ColoredBox(
        key: tvTestProbeKey,
        color: Colors.transparent,
        child: SizedBox.expand(),
      ),
    );

    expect(
      find.byKey(const ValueKey('app-presentation-tv-background')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('app-presentation-tv-safe-frame')),
      findsNothing,
    );

    final probeContext = tester.element(find.byKey(tvTestProbeKey));
    final mediaQuery = MediaQuery.of(probeContext);
    expect(mediaQuery.padding, padding);
    expect(mediaQuery.viewPadding, padding);
    expect(mediaQuery.viewInsets, viewInsets);
    expect(tester.getRect(find.byKey(tvTestProbeKey)), Offset.zero & size);

    final tokens = probeContext.presentationTokens;
    expect(tokens.safeContentFraction, 0);
    expect(tokens.bodyTypeScale, 1);
    expect(tokens.displayTypeScale, 1);
    expect(tokens.spacingScale, 1);
    expect(tokens.focusScale, 1);
    expect(FAccessibilityScope.focusHighlightOf(probeContext), isFalse);
  });

  test('gallery TV viewports distinguish logical size from output density', () {
    final hd = GalleryViewportPresets.byId('tv-720p');
    final fullHd = GalleryViewportPresets.byId('tv-1080p');
    final ultraHdEquivalent = GalleryViewportPresets.byId(
      'tv-4k-equivalent',
    );

    expect((hd.size, hd.devicePixelRatio), (const Size(1280, 720), 1));
    expect(
      (fullHd.size, fullHd.devicePixelRatio),
      (const Size(1920, 1080), 1),
    );
    expect(ultraHdEquivalent.size, fullHd.size);
    expect(ultraHdEquivalent.devicePixelRatio, 2);
    expect(
      ultraHdEquivalent.size * ultraHdEquivalent.devicePixelRatio,
      const Size(3840, 2160),
    );
  });
}

class _PolicyProbe extends ConsumerWidget {
  const _PolicyProbe();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref
      ..watch(platformCapabilitiesProvider)
      ..watch(presentationPolicyProvider);
    return Semantics(
      key: tvTestProbeKey,
      label: 'TV policy probe',
      child: const SizedBox.expand(),
    );
  }
}
