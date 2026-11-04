import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/config/app_environment.dart';
import 'package:starter/app/dependencies.dart';
import 'package:starter/app/platform_capabilities_provider.dart';
import 'package:starter/app/routing/app_link_handler.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
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

import '../../goldens/canonical_golden_harness.dart';

void main() {
  // Real type: the test engine's placeholder font is far wider than Onest, so
  // it would report overflows that no real device can produce.
  setUpAll(loadCanonicalGoldenFonts);
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));

  // Phones and desktops take different branches through the brand pages. The
  // viewport has to be the preview's own: the tester's view size alone never
  // reaches a page inside the preview frame.
  for (final viewportId in const ['compact-phone', 'desktop']) {
    testWidgets('every registered case mounts at $viewportId in the real preview composition', (
      tester,
    ) async {
      final viewport = GalleryViewportPresets.values.firstWhere(
        (preset) => preset.id == viewportId,
      );
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = viewport.size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final dependencies = AppDependencies.inMemory();
      for (final galleryCase in buildGalleryRegistry(config: _developmentConfig)) {
        await tester.pumpWidget(
          _RegistryCaseHost(
            dependencies: dependencies,
            galleryCase: galleryCase,
            viewport: viewport,
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull, reason: '${galleryCase.id} at $viewportId');
        expect(find.byKey(const ValueKey('gallery-preview-viewport')), findsOneWidget);
      }
    });
  }
}

class _RegistryCaseHost extends StatelessWidget {
  const _RegistryCaseHost({
    required this.dependencies,
    required this.galleryCase,
    required this.viewport,
  });

  final AppDependencies dependencies;
  final GalleryCase galleryCase;
  final GalleryViewportPreset viewport;

  @override
  Widget build(BuildContext context) {
    final theme = ForuiThemeFactory.build(
      brightness: Brightness.light,
      accent: AppAccent.neutral,
      fontScale: 1,
      interactionPolicy: AppInteractionPolicy.touch,
    );
    return ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(dependencies.settings.settingsRepository),
        initialSettingsProvider.overrideWithValue(dependencies.settings.initialSettings),
        platformCapabilitiesProvider.overrideWithValue(
          dependencies.platform.platformCapabilities,
        ),
        featureFlagsSourceProvider.overrideWithValue(dependencies.remoteConfig.featureFlagsSource),
        experimentSourceProvider.overrideWithValue(dependencies.remoteConfig.experimentSource),
        cacheStoreProvider.overrideWithValue(dependencies.storage.cacheStore),
        feedbackTransportProvider.overrideWithValue(dependencies.feedback.feedbackTransport),
        initialFeedbackDraftProvider.overrideWithValue(
          dependencies.feedback.initialFeedbackDraft,
        ),
        initialFeedbackShakeEnabledProvider.overrideWithValue(
          dependencies.feedback.initialFeedbackShakeEnabled,
        ),
        feedbackAppMetadataProvider.overrideWithValue(
          dependencies.feedback.feedbackAppMetadata,
        ),
      ],
      child: TranslationProvider(
        child: MaterialApp(
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: FLocalizations.localizationsDelegates,
          theme: theme.toApproximateMaterialTheme(),
          builder: (context, child) => FTheme(
            data: theme,
            child: child ?? const SizedBox.shrink(),
          ),
          home: PreviewFrame(
            environment: GalleryEnvironment.defaults().copyWith(
              viewport: viewport,
              interactionPolicy: viewport.interactionPolicy,
              animationsEnabled: false,
            ),
            child: Builder(builder: galleryCase.build),
          ),
        ),
      ),
    );
  }
}

final _developmentConfig = AppConfig(
  environment: AppEnvironment.development,
  enableVerboseLogging: false,
  enableDevTools: true,
  iosAppleId: '',
  allowedDeepLinkHosts: AllowedDeepLinkHosts.empty,
);
