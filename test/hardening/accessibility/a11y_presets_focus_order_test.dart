import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// Focus-order hardening for the accessibility-preset selector. Verifies the
/// preset tiles traverse in declared enum order (comfortable -> large ->
/// dyslexia) under keyboard Tab, in both LTR (en) and RTL (ar) — the
/// tile order is layout-driven and must not invert under RTL (FTile reverses
/// content horizontally but the vertical tab order is the widget tree order).
void main() {
  setUp(() async {
    await LocaleSettings.setLocale(AppLocale.en);
  });

  testWidgets('preset tiles traverse in enum order under Tab (LTR)', (tester) async {
    await tester.pumpWidget(_harness(locale: AppLocale.en));
    await _settle(tester);

    // Tab into the page. The first focusable preset tile is comfortable.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_focusedPresetKey(tester), 'a11y-preset-comfortable');

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_focusedPresetKey(tester), 'a11y-preset-large');

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_focusedPresetKey(tester), 'a11y-preset-dyslexia');
  });

  testWidgets('preset tiles preserve declared order under RTL (Arabic)', (tester) async {
    await LocaleSettings.setLocale(AppLocale.ar);
    await tester.pumpWidget(_harness(locale: AppLocale.ar));
    await _settle(tester);

    expect(
      Directionality.of(
        tester.element(find.byKey(const ValueKey('a11y-preset-large'))),
      ),
      TextDirection.rtl,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_focusedPresetKey(tester), 'a11y-preset-comfortable');

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_focusedPresetKey(tester), 'a11y-preset-large');

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_focusedPresetKey(tester), 'a11y-preset-dyslexia');
  });

  testWidgets('activating the focused large tile via keyboard applies the preset', (tester) async {
    await tester.pumpWidget(_harness(locale: AppLocale.en));
    await _settle(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_focusedPresetKey(tester), 'a11y-preset-large');

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await _settle(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.byKey(const ValueKey('a11y-preset-large'))),
    );
    expect(
      container.read(settingsControllerProvider).textPreset,
      AppTextPreset.large,
    );
  });
}

/// Bounded frame pump (checklist #5 — never pumpAndSettle).
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Returns the ValueKey string of the preset tile that currently holds primary
/// focus, or null when no preset tile is focused.
///
/// The `a11y-preset-*` key sits on the `FTile`, which builds its own `Focus`
/// subtree around the title/subtitle content. `Focus.of` looks UP for a Focus
/// ancestor, so we probe a descendant (the title text) that lives inside that
/// subtree rather than the `FTile` element itself.
String? _focusedPresetKey(WidgetTester tester) {
  for (final preset in AppTextPreset.values) {
    final node = Focus.of(
      tester.element(
        find
            .descendant(
              of: find.byKey(ValueKey('a11y-preset-${preset.name}')),
              matching: find.byType(Text),
            )
            .first,
      ),
    );
    if (node.hasPrimaryFocus || node.hasFocus) {
      return 'a11y-preset-${preset.name}';
    }
  }
  return null;
}

Widget _harness({
  required AppLocale locale,
}) {
  final store = InMemorySettingsStore();
  final repository = SettingsRepository(store);
  final initialState = SettingsState(
    themeMode: AppThemeMode.system,
    accent: AppAccent.neutral,
    fontScale: 1,
    localeOverride: locale,
    textPreset: AppTextPreset.comfortable,
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
