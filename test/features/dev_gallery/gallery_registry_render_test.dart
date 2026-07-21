import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/config/app_environment.dart';
import 'package:starter/app/dependencies.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/features/dev_gallery/gallery_environment.dart';
import 'package:starter/features/dev_gallery/gallery_registry.dart';
import 'package:starter/features/dev_gallery/preview_frame.dart';
import 'package:starter/features/settings/settings_controller.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/adaptive/app_interaction_policy.dart';
import 'package:starter/shared/theme/forui_theme_factory.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));

  testWidgets('every registered case mounts in the real preview composition', (tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(1440, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final dependencies = AppDependencies.inMemory();
    for (final galleryCase in buildGalleryRegistry(config: _developmentConfig)) {
      await tester.pumpWidget(
        _RegistryCaseHost(
          dependencies: dependencies,
          galleryCase: galleryCase,
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull, reason: galleryCase.id);
      expect(find.byKey(const ValueKey('gallery-preview-viewport')), findsOneWidget);
    }
  });
}

class _RegistryCaseHost extends StatelessWidget {
  const _RegistryCaseHost({required this.dependencies, required this.galleryCase});

  final AppDependencies dependencies;
  final GalleryCase galleryCase;

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
        settingsRepositoryProvider.overrideWithValue(dependencies.settingsRepository),
        initialSettingsProvider.overrideWithValue(dependencies.initialSettings),
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
);
