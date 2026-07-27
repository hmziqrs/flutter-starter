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

void main() {
  setUp(() async {
    await LocaleSettings.setLocale(AppLocale.en);
  });

  testWidgets('renders every preset tile with the current selection highlighted', (tester) async {
    await tester.pumpWidget(
      _harness(initialPreset: AppTextPreset.comfortable),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('a11y-preset-comfortable')), findsOneWidget);
    expect(find.byKey(const ValueKey('a11y-preset-large')), findsOneWidget);
    expect(find.byKey(const ValueKey('a11y-preset-dyslexia')), findsOneWidget);

    // Comfortable is selected initially.
    final comfortableTile = tester.widget<FTile>(
      find.byKey(const ValueKey('a11y-preset-comfortable')),
    );
    expect(comfortableTile.selected, isTrue);
    final largeTile = tester.widget<FTile>(
      find.byKey(const ValueKey('a11y-preset-large')),
    );
    expect(largeTile.selected, isFalse);
  });

  testWidgets('selecting the large preset updates the controller state live', (tester) async {
    await tester.pumpWidget(_harness(initialPreset: AppTextPreset.comfortable));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('a11y-preset-large')));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byKey(const ValueKey('a11y-preset-large'))),
    );
    final state = container.read(settingsControllerProvider);
    expect(state.textPreset, AppTextPreset.large);
    // The controller applies the preset's fontScale to SettingsState.
    expect(state.fontScale, AppTextPreset.large.toSettings().fontScale);

    // Selection highlight follows the new preset.
    final largeTile = tester.widget<FTile>(
      find.byKey(const ValueKey('a11y-preset-large')),
    );
    expect(largeTile.selected, isTrue);
  });

  testWidgets('surfaces common.notConnected when persistence fails (never fakes success)', (
    tester,
  ) async {
    // failWrites makes the optimistic save roll back AND the page surface the
    // honest notConnected notice (guardrail 13).
    await tester.pumpWidget(
      _harness(initialPreset: AppTextPreset.comfortable, failWrites: true),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('a11y-preset-dyslexia')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('a11y-preset-save-error')), findsOneWidget);
    expect(find.textContaining('not connected'), findsOneWidget);
  });

  testWidgets('titles are localized for Arabic (RTL)', (tester) async {
    await LocaleSettings.setLocale(AppLocale.ar);
    await tester.pumpWidget(
      _harness(initialPreset: AppTextPreset.comfortable, locale: AppLocale.ar),
    );
    await tester.pumpAndSettle();

    expect(find.text('إمكانية الوصول'), findsWidgets);
    expect(find.text('مريح'), findsOneWidget);
    expect(
      Directionality.of(
        tester.element(find.byKey(const ValueKey('a11y-preset-large'))),
      ),
      TextDirection.rtl,
    );
  });
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
