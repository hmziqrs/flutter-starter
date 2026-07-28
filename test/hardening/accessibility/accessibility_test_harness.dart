import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/config/app_environment.dart';
import 'package:starter/app/routing/app_link_handler.dart';
import 'package:starter/features/dev_gallery/gallery_environment.dart';
import 'package:starter/features/dev_gallery/gallery_registry.dart';
import 'package:starter/features/dev_gallery/preview_frame.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/adaptive/app_interaction_policy.dart';
import 'package:starter/shared/theme/forui_theme_factory.dart';

final accessibilityDevelopmentConfig = AppConfig(
  environment: AppEnvironment.development,
  enableVerboseLogging: false,
  enableDevTools: true,
  iosAppleId: '',
  allowedDeepLinkHosts: AllowedDeepLinkHosts.empty,
);

Future<void> pumpGalleryCase(
  WidgetTester tester, {
  required String caseId,
  required GalleryEnvironment environment,
  bool settle = true,
}) async {
  final galleryCase = buildGalleryRegistry(
    config: accessibilityDevelopmentConfig,
  ).singleWhere((candidate) => candidate.id == caseId);

  await pumpPreviewChild(
    tester,
    environment: environment,
    child: Builder(builder: galleryCase.build),
    settle: settle,
  );
}

Future<void> pumpPreviewChild(
  WidgetTester tester, {
  required GalleryEnvironment environment,
  required Widget child,
  bool settle = true,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = environment.viewport.size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(() => LocaleSettings.setLocale(AppLocale.en));

  await LocaleSettings.setLocale(environment.locale);
  final hostTheme = ForuiThemeFactory.build(
    brightness: Brightness.light,
    accent: AppAccent.neutral,
    fontScale: 1,
    interactionPolicy: AppInteractionPolicy.touch,
  );
  await tester.pumpWidget(
    ProviderScope(
      child: TranslationProvider(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: environment.locale.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: FLocalizations.localizationsDelegates,
          theme: hostTheme.toApproximateMaterialTheme(),
          builder: (context, materialChild) => FTheme(
            data: hostTheme,
            child: materialChild ?? const SizedBox.shrink(),
          ),
          home: PreviewFrame(
            environment: environment,
            child: child,
          ),
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

GalleryEnvironment accessibilityEnvironment({
  String viewportId = 'compact-phone',
  AppLocale locale = AppLocale.en,
  Brightness brightness = Brightness.light,
  AppInteractionPolicy interactionPolicy = AppInteractionPolicy.touch,
  bool animationsEnabled = true,
  bool highContrast = false,
  bool boldText = false,
  GallerySystemTextScale systemTextScale = GallerySystemTextScale.normal,
}) {
  return GalleryEnvironment.defaults().copyWith(
    viewport: GalleryViewportPresets.byId(viewportId),
    locale: locale,
    brightness: brightness,
    interactionPolicy: interactionPolicy,
    animationsEnabled: animationsEnabled,
    highContrast: highContrast,
    boldText: boldText,
    systemTextScale: systemTextScale,
  );
}
