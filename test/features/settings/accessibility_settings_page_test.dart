import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/settings/accessibility_settings_page.dart';
import 'package:starter/features/settings/in_memory_settings_store.dart';
import 'package:starter/features/settings/settings_controller.dart';
import 'package:starter/features/settings/settings_repository.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/features/settings/text_preset.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/adaptive/app_interaction_policy.dart';
import 'package:starter/shared/theme/forui_theme_factory.dart';
import 'package:starter/shared/widgets/brand/app_ring_marker.dart';

/// Whether the option row's ring marker is filled (picked), per BRAND.md s7.
bool _markerFilled(WidgetTester tester, String key) {
  return tester
      .widget<AppRingMarker>(
        find.descendant(of: find.byKey(ValueKey(key)), matching: find.byType(AppRingMarker)),
      )
      .filled;
}

void main() {
  setUp(() async {
    await LocaleSettings.setLocale(AppLocale.en);
  });

  testWidgets('renders every preset row with the current selection marked', (tester) async {
    await tester.pumpWidget(
      _harness(initialPreset: AppTextPreset.comfortable),
    );
    await _settle(tester);

    expect(find.byKey(const ValueKey('a11y-preset-comfortable')), findsOneWidget);
    expect(find.byKey(const ValueKey('a11y-preset-large')), findsOneWidget);
    expect(find.byKey(const ValueKey('a11y-preset-dyslexia')), findsOneWidget);

    expect(_markerFilled(tester, 'a11y-preset-comfortable'), isTrue);
    expect(_markerFilled(tester, 'a11y-preset-large'), isFalse);
  });

  testWidgets('selecting the large preset updates the controller state live', (tester) async {
    await tester.pumpWidget(_harness(initialPreset: AppTextPreset.comfortable));
    await _settle(tester);

    await tester.tap(find.byKey(const ValueKey('a11y-preset-large')));
    await _settle(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.byKey(const ValueKey('a11y-preset-large'))),
    );
    final state = container.read(settingsControllerProvider);
    expect(state.textPreset, AppTextPreset.large);
    expect(state.fontScale, AppTextPreset.large.toSettings().fontScale);

    expect(_markerFilled(tester, 'a11y-preset-large'), isTrue);
  });

  testWidgets('surfaces the save failure when persistence fails (never fakes success)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(initialPreset: AppTextPreset.comfortable, failWrites: true),
    );
    await _settle(tester);

    await tester.tap(find.byKey(const ValueKey('a11y-preset-dyslexia')));
    await _settle(tester);

    expect(find.byKey(const ValueKey('a11y-preset-save-error')), findsOneWidget);
    expect(find.textContaining("We couldn't save your change"), findsOneWidget);
  });

  testWidgets('titles are localized for Arabic (RTL)', (tester) async {
    await LocaleSettings.setLocale(AppLocale.ar);
    await tester.pumpWidget(
      _harness(initialPreset: AppTextPreset.comfortable, locale: AppLocale.ar),
    );
    await _settle(tester);

    // Exactly one "Accessibility" — the page title. The section card carries
    // no duplicate title of its own (SettingsSectionCard's contract).
    expect(find.text('إمكانية الوصول'), findsOneWidget);
    expect(find.text('مريح'), findsOneWidget);
    expect(
      Directionality.of(
        tester.element(find.byKey(const ValueKey('a11y-preset-large'))),
      ),
      TextDirection.rtl,
    );
  });
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Widget _harness({
  required AppTextPreset initialPreset,
  bool failWrites = false,
  AppLocale locale = AppLocale.en,
}) {
  final store = InMemorySettingsStore()..failWrites = failWrites;
  final repository = SettingsRepository(store);
  final presetSettings = initialPreset.toSettings();
  final initialState = SettingsState(
    themeMode: AppThemeMode.system,
    accent: AppAccent.neutral,
    fontScale: presetSettings.fontScale,
    spacingVariant: AppSpacingVariant.standard,
    radiusVariant: AppRadiusVariant.rounded,
    localeOverride: locale,
    textPreset: initialPreset,
  );
  final hostLocale = locale.flutterLocale;
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
        locale: hostLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: FLocalizations.localizationsDelegates,
        theme: theme.toApproximateMaterialTheme(),
        builder: (context, child) => FTheme(
          data: theme,
          child: child ?? const SizedBox.shrink(),
        ),
        home: const AccessibilitySettingsPage(),
      ),
    ),
  );
}
