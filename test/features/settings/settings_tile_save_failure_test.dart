import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/settings/in_memory_settings_store.dart';
import 'package:starter/features/settings/settings_controller.dart';
import 'package:starter/features/settings/settings_page.dart';
import 'package:starter/features/settings/settings_repository.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/features/settings/text_preset.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/adaptive/app_interaction_policy.dart';
import 'package:starter/shared/adaptive/app_layout_provider.dart';
import 'package:starter/shared/theme/forui_theme_factory.dart';

void main() {
  setUp(() async {
    await LocaleSettings.setLocale(AppLocale.en);
  });

  testWidgets('haptics tile surfaces common.notConnected when persistence fails', (tester) async {
    _setViewport(tester);
    await tester.pumpWidget(_harness(failWrites: true));
    await _settle(tester);

    expect(find.byKey(const ValueKey('settings-toggle-haptics')), findsOneWidget);
    expect(find.byKey(const ValueKey('settings-toggle-save-error')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('settings-toggle-haptics')));
    await _settle(tester);

    expect(find.byKey(const ValueKey('settings-toggle-save-error')), findsOneWidget);
    expect(find.textContaining('not connected'), findsWidgets);
  });

  testWidgets('a succeeding write leaves no failure text behind', (tester) async {
    _setViewport(tester);
    await tester.pumpWidget(_harness());
    await _settle(tester);

    await tester.tap(find.byKey(const ValueKey('settings-toggle-haptics')));
    await _settle(tester);

    expect(find.byKey(const ValueKey('settings-toggle-save-error')), findsNothing);

    final container = ProviderScope.containerOf(
      tester.element(find.byKey(const ValueKey('settings-toggle-haptics'))),
    );
    expect(container.read(settingsControllerProvider).hapticsEnabled, isFalse);
  });

  testWidgets('the failure clears once a later write succeeds', (tester) async {
    _setViewport(tester);
    final store = InMemorySettingsStore()..failWrites = true;
    await tester.pumpWidget(_harness(store: store));
    await _settle(tester);

    await tester.tap(find.byKey(const ValueKey('settings-toggle-haptics')));
    await _settle(tester);
    expect(find.byKey(const ValueKey('settings-toggle-save-error')), findsOneWidget);

    store.failWrites = false;
    await tester.tap(find.byKey(const ValueKey('settings-toggle-haptics')));
    await _settle(tester);

    expect(find.byKey(const ValueKey('settings-toggle-save-error')), findsNothing);
  });
}

/// The appearance section renders the haptics tile below a default 600px
/// viewport, so every case needs a surface tall enough to hit-test it.
void _setViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Widget _harness({bool failWrites = false, InMemorySettingsStore? store}) {
  final settingsStore = store ?? (InMemorySettingsStore()..failWrites = failWrites);
  final repository = SettingsRepository(settingsStore);
  const initialState = SettingsState(
    themeMode: AppThemeMode.system,
    accent: AppAccent.neutral,
    fontScale: 1,
    localeOverride: AppLocale.en,
    textPreset: AppTextPreset.comfortable,
  );
  final theme = ForuiThemeFactory.build(
    brightness: Brightness.light,
    accent: AppAccent.neutral,
    fontScale: 1,
    interactionPolicy: AppInteractionPolicy.touch,
  );
  return ProviderScope(
    overrides: [
      settingsRepositoryProvider.overrideWithValue(repository),
      initialSettingsProvider.overrideWithValue(initialState),
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
        home: AppLayoutScope(
          builder: (context, _) => SettingsPage(
            section: SettingsSection.appearance,
            onOpenAppearance: () {},
            onOpenLanguage: () {},
            onOpenAccessibility: () {},
            onOpenAccount: () {},
            onOpenSubscription: () {},
            onOpenPrivacyAbout: () {},
            onOpenProfile: () {},
            onOpenLogin: () {},
            onOpenPricing: () {},
            onOpenPasscodeSetup: () {},
            onOpenTerms: () {},
            onOpenPrivacy: () {},
            onOpenLicense: () {},
            loadBuildLabel: () async => 'test-build',
          ),
        ),
      ),
    ),
  );
}
