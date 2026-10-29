import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/app/interaction_policy_controller.dart';
import 'package:starter/app/platform_capabilities_provider.dart';
import 'package:starter/app/presentation_policy_controller.dart';
import 'package:starter/features/dev_gallery/cases/brand_system_gallery_cases.dart';
import 'package:starter/features/dev_gallery/gallery_case.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/platform/platform_capabilities.dart';
import 'package:starter/shared/adaptive/app_interaction_policy.dart';
import 'package:starter/shared/adaptive/app_presentation_policy.dart';
import 'package:starter/shared/theme/brand_tokens.dart';
import 'package:starter/shared/theme/forui_theme_factory.dart';
import 'package:starter/shared/widgets/brand/app_ring_gauge.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));

  test('case IDs cover every brand story on one screen', () {
    final cases = buildBrandSystemGalleryCases();
    final ids = cases.map((galleryCase) => galleryCase.id).toList();

    expect(ids, [
      'brandSystem.wordmark',
      'brandSystem.markers',
      'brandSystem.statusTags',
      'brandSystem.iconTiles',
      'brandSystem.notices',
      'brandSystem.ringGauges',
      'brandSystem.surfaces',
      'brandSystem.palette',
      'brandSystem.type',
    ]);
    expect(cases.every((galleryCase) => galleryCase.screenId == 'brandSystem'), isTrue);
  });

  testWidgets('ring gauge draws the oxide arc under a neutral-accent host', (tester) async {
    await _pumpCase(tester, 'brandSystem.ringGauges');

    final gaugeTheme = FTheme.of(tester.element(find.byType(AppRingGauge).first));
    expect(gaugeTheme.colors.primary, AppBrandColors.light.oxide);
    expect(tester.takeException(), isNull);
  });

  testWidgets('default icon tile tone is the oxide primary, not the host accent', (tester) async {
    await _pumpCase(tester, 'brandSystem.iconTiles');

    expect(
      tester.widget<Icon>(find.byIcon(FLucideIcons.download)).color,
      AppBrandColors.light.oxide,
    );
    expect(tester.takeException(), isNull);
  });
}

/// Pumps a brand-system case under the gallery's default host theme: the
/// neutral accent, whose primary is grey.
Future<void> _pumpCase(WidgetTester tester, String caseId) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  final hostTheme = ForuiThemeFactory.build(
    brightness: Brightness.light,
    accent: AppAccent.neutral,
    fontScale: 1,
    interactionPolicy: AppInteractionPolicy.touch,
  );
  final galleryCase = _caseById(buildBrandSystemGalleryCases(), caseId);
  await tester.pumpWidget(
    TranslationProvider(
      child: MaterialApp(
        theme: hostTheme.toApproximateMaterialTheme(),
        builder: (context, child) =>
            FTheme(data: hostTheme, child: child ?? const SizedBox.shrink()),
        home: ProviderScope(
          overrides: [
            platformCapabilitiesProvider.overrideWithValue(
              const PlatformCapabilities.nonTelevision(),
            ),
            interactionPolicyOverrideProvider.overrideWithValue(AppInteractionPolicy.touch),
            presentationPolicyOverrideProvider.overrideWithValue(
              const AppPresentationPolicy(
                viewingEnvironment: AppViewingEnvironment.nearField,
                interactionPolicy: AppInteractionPolicy.touch,
              ),
            ),
          ],
          child: Builder(builder: galleryCase.build),
        ),
      ),
    ),
  );
  await tester.pump();
}

GalleryCase _caseById(List<GalleryCase> cases, String id) =>
    cases.singleWhere((galleryCase) => galleryCase.id == id);
