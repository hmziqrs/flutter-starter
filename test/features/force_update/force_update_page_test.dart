import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/force_update/force_update_page.dart';
import 'package:starter/features/force_update/force_update_state.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/escape_dismissible_overlay.dart';

const _state = ForceUpdateState(
  latestVersion: '2.1.0',
  storeUrl: 'https://example.test/store',
);

Widget _localizedApp({required Widget home}) {
  return ProviderScope(
    child: TranslationProvider(
      child: Builder(
        builder: (context) {
          final localeData = TranslationProvider.of(context);
          final theme = generated.lightTheme;
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: home,
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
          );
        },
      ),
    ),
  );
}

void main() {
  testWidgets('renders title, body and the single Update now action', (tester) async {
    await tester.pumpWidget(
      _localizedApp(
        home: const ForceUpdatePage(state: _state, onUpdateNow: _noop),
      ),
    );
    await tester.pump();

    final translations = tester.element(find.byType(ForceUpdatePage)).t;
    expect(find.text(translations.forceUpdate.title), findsOneWidget);
    expect(find.text(translations.forceUpdate.body), findsOneWidget);
    expect(find.text(translations.forceUpdate.updateNow), findsOneWidget);
  });

  testWidgets('uses the server message in place of the default body', (tester) async {
    await tester.pumpWidget(
      _localizedApp(
        home: const ForceUpdatePage(
          state: ForceUpdateState(
            latestVersion: '2.1.0',
            storeUrl: 'https://example.test/store',
            message: 'Critical security patch',
          ),
          onUpdateNow: _noop,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Critical security patch'), findsOneWidget);
  });

  testWidgets('Update now invokes the callback', (tester) async {
    var pressed = 0;
    await tester.pumpWidget(
      _localizedApp(
        home: ForceUpdatePage(state: _state, onUpdateNow: () => pressed += 1),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('force-update-update-now')));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(pressed, 1);
  });

  testWidgets('hard block is non-dismissible (PopScope.canPop is false)', (tester) async {
    await tester.pumpWidget(
      _localizedApp(
        home: const ForceUpdatePage(state: _state, onUpdateNow: _noop),
      ),
    );
    await tester.pump();

    final scope = tester.widget<PopScope>(find.byType(PopScope));
    expect(scope.canPop, isFalse);
  });

  testWidgets('hard block is NOT wrapped in EscapeDismissibleOverlay', (tester) async {
    await tester.pumpWidget(
      _localizedApp(
        home: const ForceUpdatePage(state: _state, onUpdateNow: _noop),
      ),
    );
    await tester.pump();

    expect(find.byType(EscapeDismissibleOverlay), findsNothing);
  });
}

void _noop() {}
