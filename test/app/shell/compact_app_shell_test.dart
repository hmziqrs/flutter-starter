import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/app/shell/compact_app_shell.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/adaptive/app_interaction_policy.dart';
import 'package:starter/shared/theme/forui_theme_factory.dart';

void main() {
  testWidgets('selected destination reads as the muted selection, not orange', (
    tester,
  ) async {
    await _pumpShell(tester, selectedIndex: 1);

    final context = tester.element(find.byKey(const ValueKey('compact-navigation')));
    final theme = context.theme;
    final bar = tester.widget<FBottomNavigationBar>(
      find.byKey(const ValueKey('compact-navigation')),
    );
    final itemStyle = bar.style(theme.bottomNavigationBarStyle).itemStyle;

    // APP-BLOCKS AppShell states: the active item's label is text-foreground —
    // ForUI's stock selected style would announce it in colors.primary (oxide
    // orange under the default accent).
    final selectedLabel = itemStyle.textStyle.resolve({FTappableVariant.selected});
    expect(selectedLabel.color, theme.colors.foreground);
    expect(selectedLabel.fontWeight, FontWeight.w600);

    // Only the icon carries the brand color.
    final selectedIcon = itemStyle.iconStyle.resolve({FTappableVariant.selected});
    expect(selectedIcon.color, theme.colors.primary);

    // Unselected labels stay muted.
    expect(itemStyle.textStyle.resolve({}).color, theme.colors.mutedForeground);
  });

  testWidgets('tapping a destination still selects it', (tester) async {
    var selected = -1;
    await _pumpShell(tester, selectedIndex: 0, onSelectTab: (index) => selected = index);

    await tester.tap(find.byIcon(FLucideIcons.settings));
    await tester.pumpAndSettle();

    expect(selected, 2);
  });
}

Future<void> _pumpShell(
  WidgetTester tester, {
  required int selectedIndex,
  ValueChanged<int>? onSelectTab,
}) async {
  await LocaleSettings.setLocale(AppLocale.en);
  final theme = ForuiThemeFactory.build(
    brightness: Brightness.light,
    accent: AppAccent.neutral,
    fontScale: 1,
    interactionPolicy: AppInteractionPolicy.touch,
  );

  await tester.pumpWidget(
    TranslationProvider(
      child: MaterialApp(
        locale: AppLocale.en.flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: FLocalizations.localizationsDelegates,
        theme: theme.toApproximateMaterialTheme(),
        home: FTheme(
          data: theme,
          child: CompactAppShell(
            selectedIndex: selectedIndex,
            onSelectTab: onSelectTab ?? (_) {},
            child: const SizedBox.shrink(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
