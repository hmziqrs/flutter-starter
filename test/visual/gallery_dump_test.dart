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
import 'package:starter/shared/theme/forui_theme_factory.dart';

/// Renders every gallery case to a PNG so component work can be measured
/// pixel-by-pixel against the brand storybook photographs — headlessly,
/// without touching the desktop.
///
/// One-off tool, never a baseline: `just visual` renders the phone and desktop
/// sets under `build/visual/`. A plain `flutter test` skips it, because the
/// output folder is gitignored and absent on a clean clone. Layout exceptions
/// are collected per case into `_report.txt`, so one bad case cannot hide the
/// renders of the others; the run fails at the end if any were found.
void main() {
  const viewportId = String.fromEnvironment('VISUAL_VIEWPORT', defaultValue: 'compact-phone');
  final preset = GalleryViewportPresets.values.firstWhere((preset) => preset.id == viewportId);
  const outputDir = viewportId == 'compact-phone' ? 'build/visual' : 'build/visual/$viewportId';
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

  testWidgets('dump every gallery case (dark + light)', skip: !autoUpdateGoldenFiles, (
    tester,
  ) async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    tester.view
      ..devicePixelRatio = 2
      ..physicalSize = preset.size * 2;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final cases = buildGalleryRegistry(config: config);
    final dependencies = AppDependencies.inMemory();
    final boundaryKey = GlobalKey();
    Directory(outputDir).createSync(recursive: true);
    final problems = <String>[];
    final previousOnError = FlutterError.onError;

    for (final brightness in Brightness.values) {
      final theme = ForuiThemeFactory.build(
        brightness: brightness,
        accent: AppAccent.oxide,
        fontScale: 1,
        interactionPolicy: preset.interactionPolicy,
      );
      for (final galleryCase in cases) {
        final reported = <String>[];
        FlutterError.onError = (details) => reported.add(details.exceptionAsString());
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
                      viewport: preset,
                      interactionPolicy: preset.interactionPolicy,
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

        final captured = tester.takeException();
        if (captured != null) reported.add(captured.toString());
        FlutterError.onError = previousOnError;
        if (reported.isNotEmpty) {
          final summary = reported.map((error) => error.split('\n').first).toSet().join(' | ');
          problems.add('${galleryCase.id}.${brightness.name}: $summary');
        }

        await expectLater(
          find.byKey(boundaryKey),
          matchesGoldenFile('../../$outputDir/${galleryCase.id}.${brightness.name}.png'),
        );

        // Cases push dialogs/routes onto the navigator; pumping a teardown
        // destroys the whole subtree so nothing leaks into the next case
        // (pumpWidget would only UPDATE the same-key tree in place).
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    }

    File('$outputDir/_report.txt').writeAsStringSync(
      problems.isEmpty ? 'clean\n' : '${problems.join('\n')}\n',
    );
    expect(problems, isEmpty, reason: 'Layout exceptions; see $outputDir/_report.txt');
  });
}
