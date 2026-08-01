import 'dart:ui' show Brightness, PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/features/dev_gallery/gallery_environment.dart';
import 'package:starter/features/dev_gallery/preview_frame.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/adaptive/app_interaction_policy.dart';
import 'package:starter/shared/theme/forui_theme_factory.dart';

export 'package:starter/i18n/translations.g.dart' show AppLocale;

const canonicalGoldenSettleTime = Duration(milliseconds: 500);

const ValueKey<String> canonicalGoldenBoundaryKey = ValueKey(
  'canonical-golden-boundary',
);

final class CanonicalGoldenFixture {
  const CanonicalGoldenFixture({
    required this.name,
    required this.viewport,
    required this.locale,
    required this.brightness,
    required this.interactionPolicy,
    required this.galleryCase,
    this.systemTextScale = GallerySystemTextScale.normal,
    this.appFontScale = 1,
    this.focusedFieldKey,
  });

  final String name;
  final Size viewport;
  final AppLocale locale;
  final Brightness brightness;
  final AppInteractionPolicy interactionPolicy;
  final GalleryCase galleryCase;
  final GallerySystemTextScale systemTextScale;
  final double appFontScale;
  final Key? focusedFieldKey;

  String get baselinePath => 'baselines/$name.png';
}

Future<void> loadCanonicalGoldenFonts() async {
  await Future.wait([
    _loadFontFamily('Noto Sans', const [
      'assets/fonts/Noto_Sans/NotoSans.ttf',
      'assets/fonts/Noto_Sans/NotoSans-Italic.ttf',
    ]),
    _loadFontFamily('Noto Sans Arabic', const [
      'assets/fonts/Noto_Sans_Arabic/NotoSansArabic.ttf',
      'assets/fonts/Noto_Sans_Arabic/NotoSansArabic-Medium.ttf',
      'assets/fonts/Noto_Sans_Arabic/NotoSansArabic-SemiBold.ttf',
      'assets/fonts/Noto_Sans_Arabic/NotoSansArabic-Bold.ttf',
    ]),
    _loadFontFamily('Noto Sans SC', const [
      'assets/fonts/Noto_Sans_SC/NotoSansSC.ttf',
    ]),
    _loadFontFamily('packages/forui_assets/ForuiLucideIcons', const [
      'packages/forui_assets/assets/lucide.ttf',
    ]),
  ]);
}

Future<void> _loadFontFamily(String family, List<String> assets) async {
  final loader = FontLoader(family);
  for (final asset in assets) {
    loader.addFont(rootBundle.load(asset));
  }
  await loader.load();
}

Future<void> expectCanonicalGolden(
  WidgetTester tester,
  CanonicalGoldenFixture fixture,
) async {
  final previousLocale = LocaleSettings.currentLocale;
  final previousFocus = FocusManager.instance.primaryFocus;

  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = fixture.viewport;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(() async {
    FocusManager.instance.primaryFocus?.unfocus();
    previousFocus?.requestFocus();
    await LocaleSettings.setLocale(previousLocale);
  });

  TestPointer? pointer;
  if (fixture.interactionPolicy == AppInteractionPolicy.precisionPointer) {
    pointer = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(
      pointer.addPointer(location: const Offset(-100, -100)),
    );
    addTearDown(() async {
      await tester.sendEventToBinding(pointer!.removePointer());
    });
  }

  FocusManager.instance.primaryFocus?.unfocus();
  await LocaleSettings.setLocale(fixture.locale);
  await tester.pumpWidget(_CanonicalGoldenApp(fixture: fixture));
  await tester.pump();
  await tester.pump(canonicalGoldenSettleTime);

  expect(tester.takeException(), isNull);
  expect(tester.view.devicePixelRatio, 1);
  expect(tester.view.physicalSize, fixture.viewport);
  expect(LocaleSettings.currentLocale, fixture.locale);

  final focusedFieldKey = fixture.focusedFieldKey;
  if (focusedFieldKey == null) {
    expect(
      tester
          .widgetList<EditableText>(find.byType(EditableText))
          .every((editable) => !editable.focusNode.hasFocus),
      isTrue,
    );
  } else {
    final editable = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(focusedFieldKey),
        matching: find.byType(EditableText),
      ),
    );
    expect(editable.focusNode.hasFocus, isTrue);
  }

  await expectLater(
    find.byKey(canonicalGoldenBoundaryKey),
    matchesGoldenFile(fixture.baselinePath),
  );
}

final class _CanonicalGoldenApp extends StatelessWidget {
  const _CanonicalGoldenApp({required this.fixture});

  final CanonicalGoldenFixture fixture;

  @override
  Widget build(BuildContext context) {
    final hostTheme = ForuiThemeFactory.build(
      brightness: fixture.brightness,
      accent: AppAccent.neutral,
      fontScale: fixture.appFontScale,
      interactionPolicy: fixture.interactionPolicy,
    );
    final environment = GalleryEnvironment.defaults().copyWith(
      viewport: GalleryViewportPreset(
        id: fixture.name,
        size: fixture.viewport,
        labelBuilder: (_) => fixture.name,
      ),
      brightness: fixture.brightness,
      accent: AppAccent.neutral,
      locale: fixture.locale,
      appFontScale: fixture.appFontScale,
      systemTextScale: fixture.systemTextScale,
      interactionPolicy: fixture.interactionPolicy,
      animationsEnabled: false,
      highContrast: false,
      boldText: false,
      safeAreaEnabled: false,
      keyboardInsetsEnabled: false,
      displayFeature: GalleryDisplayFeature.none,
    );

    return ProviderScope(
      child: TranslationProvider(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: fixture.locale.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: FLocalizations.localizationsDelegates,
          theme: hostTheme.toApproximateMaterialTheme(),
          builder: (context, child) => FTheme(
            data: hostTheme,
            child: child ?? const SizedBox.shrink(),
          ),
          home: RepaintBoundary(
            key: canonicalGoldenBoundaryKey,
            child: PreviewFrame(
              environment: environment,
              child: Builder(builder: fixture.galleryCase.build),
            ),
          ),
        ),
      ),
    );
  }
}
