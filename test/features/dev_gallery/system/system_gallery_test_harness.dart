import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/app/platform_capabilities_provider.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/features/experiments/experiment_source.dart';
import 'package:starter/features/experiments/in_memory_experiment_source.dart';
import 'package:starter/features/feature_flags/feature_flags_source.dart';
import 'package:starter/features/feature_flags/in_memory_feature_flags_source.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/cache/cache_store.dart';
import 'package:starter/infrastructure/cache/in_memory_cache_store.dart';
import 'package:starter/infrastructure/platform/platform_capabilities.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;

Widget systemGalleryTestApp({
  required GalleryCase galleryCase,
  double bottomViewInset = 0,
}) {
  return ProviderScope(
    // Mirror the production composition root: the DiagnosticsPage case reads
    // featureFlagsControllerProvider, experimentAssignmentsProvider, and
    // cacheStoreProvider — each throws until its port is overridden. Seed the
    // no-backend / real-local defaults for every system case.
    overrides: [
      platformCapabilitiesProvider.overrideWithValue(
        const PlatformCapabilities.nonTelevision(),
      ),
      featureFlagsSourceProvider.overrideWithValue(InMemoryFeatureFlagsSource()),
      experimentSourceProvider.overrideWithValue(InMemoryExperimentSource()),
      cacheStoreProvider.overrideWithValue(InMemoryCacheStore()),
    ],
    child: TranslationProvider(
      child: Builder(
        builder: (context) {
          final localeData = TranslationProvider.of(context);
          final theme = generated.lightTheme;
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: localeData.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: FLocalizations.localizationsDelegates,
            theme: theme.toApproximateMaterialTheme(),
            builder: (context, child) => FTheme(
              data: theme,
              child: FToaster(
                child: FTooltipGroup(
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            ),
            home: Builder(
              builder: (context) {
                final mediaQuery = MediaQuery.of(context);
                return MediaQuery(
                  data: mediaQuery.copyWith(
                    viewInsets: EdgeInsets.only(bottom: bottomViewInset),
                  ),
                  child: galleryCase.build(context),
                );
              },
            ),
          );
        },
      ),
    ),
  );
}

void setSystemGalleryTestViewport(WidgetTester tester, Size size) {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}
