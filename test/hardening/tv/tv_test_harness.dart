import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/app/interaction_policy_controller.dart';
import 'package:starter/app/platform_capabilities_provider.dart';
import 'package:starter/app/presentation/app_presentation_viewport.dart';
import 'package:starter/app/presentation_policy_controller.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/platform/platform_capabilities.dart';
import 'package:starter/shared/adaptive/app_interaction_policy.dart';
import 'package:starter/shared/adaptive/app_presentation_policy.dart';
import 'package:starter/shared/theme/forui_theme_factory.dart';

const tvRemotePolicy = AppPresentationPolicy(
  viewingEnvironment: AppViewingEnvironment.tenFoot,
  interactionPolicy: AppInteractionPolicy.remote,
);

const nearFieldTouchPolicy = AppPresentationPolicy(
  viewingEnvironment: AppViewingEnvironment.nearField,
  interactionPolicy: AppInteractionPolicy.touch,
);

const androidTvCapabilities = PlatformCapabilities(
  platform: 'android',
  isWeb: false,
  tvPlatform: AppTvPlatform.androidTv,
);

const nonTelevisionCapabilities = PlatformCapabilities.nonTelevision();

const tvTestProbeKey = ValueKey<String>('tv-test-probe');

void configureTvTestView(
  WidgetTester tester, {
  Size size = const Size(1920, 1080),
  double devicePixelRatio = 1,
}) {
  final previousLocale = LocaleSettings.currentLocale;
  final previousHighlightStrategy = FocusManager.instance.highlightStrategy;

  LocaleSettings.setLocaleSync(AppLocale.en);
  FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
  tester.view
    ..devicePixelRatio = devicePixelRatio
    ..physicalSize = size * devicePixelRatio;

  addTearDown(() {
    FocusManager.instance.primaryFocus?.unfocus();
    FocusManager.instance.highlightStrategy = previousHighlightStrategy;
    LocaleSettings.setLocaleSync(previousLocale);
    tester.view
      ..resetDevicePixelRatio()
      ..resetPhysicalSize();
  });
}

/// TV focus highlights and platform animations never quiesce; never pumpAndSettle here.
Future<void> pumpTvFrames(
  WidgetTester tester, {
  int frames = 8,
  Duration frameDuration = const Duration(milliseconds: 100),
}) async {
  assert(frames > 0, 'frames must be positive.');
  for (var frame = 0; frame < frames; frame += 1) {
    await tester.pump(frameDuration);
  }
}

Future<void> pumpTvPresentationHarness(
  WidgetTester tester, {
  required PlatformCapabilities capabilities,
  required Widget child,
  AppPresentationPolicy? policyOverride,
  MediaQueryData? mediaQueryData,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        platformCapabilitiesProvider.overrideWithValue(capabilities),
        if (policyOverride != null)
          interactionPolicyOverrideProvider.overrideWithValue(
            policyOverride.interactionPolicy,
          ),
        if (policyOverride != null)
          presentationPolicyOverrideProvider.overrideWithValue(policyOverride),
      ],
      child: TranslationProvider(
        child: Consumer(
          builder: (context, ref, _) {
            final policy = ref.watch(presentationPolicyProvider);
            final theme = ForuiThemeFactory.build(
              brightness: Brightness.light,
              accent: AppAccent.neutral,
              fontScale: 1,
              interactionPolicy: policy.interactionPolicy,
              presentationPolicy: policy,
            );
            final mediaQuery =
                mediaQueryData ??
                MediaQueryData(
                  size: tester.view.physicalSize / tester.view.devicePixelRatio,
                  devicePixelRatio: tester.view.devicePixelRatio,
                );

            return MaterialApp(
              debugShowCheckedModeBanner: false,
              locale: AppLocale.en.flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: FLocalizations.localizationsDelegates,
              theme: theme.toApproximateMaterialTheme(),
              home: MediaQuery(
                data: mediaQuery,
                child: AppPresentationScope(
                  policy: policy,
                  child: Theme(
                    data: theme.toApproximateMaterialTheme(),
                    child: FTheme(
                      data: theme,
                      accessibility: FAccessibility(
                        accessibleNavigation: false,
                        motion: FAccessibilityMotion.disabled,
                        focusHighlight: policy.usesDirectionalFocus,
                      ),
                      motion: const FThemeMotion(duration: Duration.zero),
                      child: AppPresentationViewport(child: child),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
  await pumpTvFrames(tester);
}

/// Avoids WidgetsApp so directional keys reach the host unconsumed.
Future<void> pumpTvKeyboardHarness(
  WidgetTester tester, {
  required AppInteractionPolicy interactionPolicy,
  required Widget child,
}) async {
  const policy = tvRemotePolicy;
  final resolvedPolicy = AppPresentationPolicy(
    viewingEnvironment: policy.viewingEnvironment,
    interactionPolicy: interactionPolicy,
  );
  final theme = ForuiThemeFactory.build(
    brightness: Brightness.light,
    accent: AppAccent.neutral,
    fontScale: 1,
    interactionPolicy: interactionPolicy,
    presentationPolicy: resolvedPolicy,
  );

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: tester.view.physicalSize / tester.view.devicePixelRatio,
        devicePixelRatio: tester.view.devicePixelRatio,
        disableAnimations: true,
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: AppPresentationScope(
          policy: resolvedPolicy,
          child: Theme(
            data: theme.toApproximateMaterialTheme(),
            child: FTheme(
              data: theme,
              accessibility: FAccessibility(
                accessibleNavigation: false,
                motion: FAccessibilityMotion.disabled,
                focusHighlight: resolvedPolicy.usesDirectionalFocus,
              ),
              motion: const FThemeMotion(duration: Duration.zero),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
  await pumpTvFrames(tester, frames: 2);
}
