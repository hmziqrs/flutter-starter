import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/config/app_environment.dart';
import 'package:starter/app/dependencies.dart';
import 'package:starter/app/platform_capabilities_provider.dart';
import 'package:starter/app/routing/app_link_handler.dart';
import 'package:starter/features/dev_gallery/gallery_environment.dart';
import 'package:starter/features/dev_gallery/gallery_registry.dart';
import 'package:starter/features/dev_gallery/preview_frame.dart';
import 'package:starter/features/experiments/experiment_source.dart';
import 'package:starter/features/feature_flags/feature_flags_source.dart';
import 'package:starter/features/feedback/feedback_controller.dart';
import 'package:starter/features/feedback/feedback_transport.dart';
import 'package:starter/features/settings/settings_controller.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/cache/cache_store.dart';
import 'package:starter/shared/adaptive/app_interaction_policy.dart';
import 'package:starter/shared/theme/forui_theme_factory.dart';

/// Renders every gallery case to a PNG under `build/visual/` so component
/// work can be measured pixel-by-pixel against the brand storybook
/// photographs — headlessly, without touching the desktop.
///
/// One-off tool, never a CI baseline: run with
/// `flutter test test/visual_dump_test.dart --update-goldens` and filter to
/// one family with `--plain-name '<screenId>'`. build/ is gitignored.
void main() {
  const outputDir = 'build/visual';
  final config = AppConfig(
    environment: AppEnvironment.development,
    enableVerboseLogging: false,
    enableDevTools: true,
    iosAppleId: '',
    allowedDeepLinkHosts: AllowedDeepLinkHosts.empty,
  );

  setUpAll(() async {
    // Real bundled typography: the Ahem fallback renders 1em-per-glyph boxes
    // that would poison any spacing comparison.
    final onest = FontLoader('Onest')
      ..addFont(rootBundle.load('assets/fonts/Onest/onest-latin-400-normal.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Onest/onest-latin-500-normal.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Onest/onest-latin-600-normal.ttf'));
    await onest.load();
    final mono = FontLoader('JetBrains Mono')
      ..addFont(rootBundle.load('assets/fonts/JetBrains_Mono/jetbrains-mono-latin-400-normal.ttf'));
    await mono.load();
    // The Forui icon font: without it every FButton/notice icon renders as
    // tofu in the dumps. Package fonts resolve under the qualified family,
    // and registering through loadFontFromList is what actually binds the
    // bytes in the test engine (FontLoader under the bare name does not).
    final lucide = await rootBundle.load('packages/forui_assets/assets/lucide.ttf');
    await ui.loadFontFromList(
      lucide.buffer.asUint8List(),
      fontFamily: 'packages/forui_assets/ForuiLucideIcons',
    );
  });

  testWidgets('dump every gallery case (dark + light)', (tester) async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    tester.view
      ..devicePixelRatio = 2
      ..physicalSize = const Size(780, 1688);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final cases = buildGalleryRegistry(config: config);
    final dependencies = AppDependencies.inMemory();
    final boundaryKey = GlobalKey();
    Directory(outputDir).createSync(recursive: true);

    for (final brightness in Brightness.values) {
      final theme = ForuiThemeFactory.build(
        brightness: brightness,
        accent: AppAccent.oxide,
        fontScale: 1,
        interactionPolicy: AppInteractionPolicy.touch,
      );
      for (final galleryCase in cases) {
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundaryKey,
            child: ProviderScope(
              overrides: [
                settingsRepositoryProvider.overrideWithValue(
                  dependencies.settings.settingsRepository,
                ),
                initialSettingsProvider.overrideWithValue(
                  dependencies.settings.initialSettings,
                ),
                platformCapabilitiesProvider.overrideWithValue(
                  dependencies.platform.platformCapabilities,
                ),
                featureFlagsSourceProvider.overrideWithValue(
                  dependencies.remoteConfig.featureFlagsSource,
                ),
                experimentSourceProvider.overrideWithValue(
                  dependencies.remoteConfig.experimentSource,
                ),
                cacheStoreProvider.overrideWithValue(dependencies.storage.cacheStore),
                feedbackTransportProvider.overrideWithValue(
                  dependencies.feedback.feedbackTransport,
                ),
                initialFeedbackDraftProvider.overrideWithValue(
                  dependencies.feedback.initialFeedbackDraft,
                ),
                feedbackAppMetadataProvider.overrideWithValue(
                  dependencies.feedback.feedbackAppMetadata,
                ),
              ],
              child: TranslationProvider(
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  locale: AppLocale.en.flutterLocale,
                  supportedLocales: AppLocaleUtils.supportedLocales,
                  localizationsDelegates: FLocalizations.localizationsDelegates,
                  theme: theme.toApproximateMaterialTheme(),
                  builder: (context, child) => FTheme(
                    data: theme,
                    child: child ?? const SizedBox.shrink(),
                  ),
                  home: PreviewFrame(
                    environment: GalleryEnvironment.defaults().copyWith(
                      brightness: brightness,
                      animationsEnabled: false,
                    ),
                    child: Builder(builder: galleryCase.build),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump();

        await expectLater(
          find.byKey(boundaryKey),
          matchesGoldenFile('../$outputDir/${galleryCase.id}.${brightness.name}.png'),
        );

        // Cases push dialogs/routes onto the navigator; pumping a teardown
        // destroys the whole subtree so nothing leaks into the next case
        // (pumpWidget would only UPDATE the same-key tree in place).
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    }
  });
}
