import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/search/debounced_query_controller.dart';
import 'package:starter/features/search/search_page.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;

Future<void> _pumpFrames(WidgetTester tester) async {
  for (var frame = 0; frame < 8; frame += 1) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Widget _harness({required Widget child}) {
  return TranslationProvider(
    child: ProviderScope(
      child: Builder(
        builder: (context) {
          final localeData = TranslationProvider.of(context);
          final theme = generated.lightTheme;
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: localeData.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: FLocalizations.localizationsDelegates,
            theme: theme.toApproximateMaterialTheme(),
            home: Scaffold(body: child),
            builder: (context, built) {
              return Directionality(
                textDirection: localeData.locale == AppLocale.ar
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: FTheme(
                  data: theme,
                  child: FToaster(
                    child: FTooltipGroup(child: built ?? const SizedBox.shrink()),
                  ),
                ),
              );
            },
          );
        },
      ),
    ),
  );
}

void main() {
  group('SearchPage', () {
    testWidgets('renders the field and the first page of local results', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(child: SearchPage(autofocus: false, onBack: () {})),
      );
      await _pumpFrames(tester);

      expect(find.byKey(const ValueKey('search-field')), findsOneWidget);
      expect(find.text('Authentication'), findsOneWidget);
      expect(find.byKey(const ValueKey('search-back')), findsOneWidget);
    });

    testWidgets('typing a debounced query filters the local results', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(child: SearchPage(autofocus: false, onBack: () {})),
      );
      await _pumpFrames(tester);
      expect(find.text('Authentication'), findsOneWidget);

      await tester.enterText(find.byType(EditableText), 'biometric');
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        'biometric',
      );

      await tester.pump(debounceQueryDuration);
      await _pumpFrames(tester);

      expect(find.text('Biometric unlock'), findsOneWidget);
      expect(find.text('Authentication'), findsNothing);
    });

    testWidgets('onBack fires when the back affordance is tapped', (
      tester,
    ) async {
      var backCalls = 0;
      await tester.pumpWidget(
        _harness(
          child: SearchPage(autofocus: false, onBack: () => backCalls += 1),
        ),
      );
      await _pumpFrames(tester);
      await tester.tap(find.byKey(const ValueKey('search-back')));
      await _pumpFrames(tester);
      expect(backCalls, 1);
    });
  });
}
