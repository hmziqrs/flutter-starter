import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/adaptive/app_layout_class.dart';
import 'package:starter/shared/adaptive/app_layout_provider.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/lists/responsive_list_grid.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  group('ResponsiveListGrid', () {
    testWidgets('uses one column under compact layout', (tester) async {
      await tester.pumpWidget(
        _harness(
          layout: AppLayoutClass.compact,
          child: ResponsiveListGrid<String>(
            items: const ['a', 'b', 'c'],
            keyOf: (item) => item,
            itemBuilder: (_, item) => SizedBox(child: Center(child: Text(item))),
          ),
        ),
      );
      await _pumpFrames(tester);

      final delegate = _gridDelegate(tester);
      expect(delegate.crossAxisCount, 1);
    });

    testWidgets('uses two columns under medium layout', (tester) async {
      await tester.pumpWidget(
        _harness(
          layout: AppLayoutClass.medium,
          child: ResponsiveListGrid<String>(
            items: const ['a', 'b', 'c'],
            keyOf: (item) => item,
            itemBuilder: (_, item) => SizedBox(child: Center(child: Text(item))),
          ),
        ),
      );
      await _pumpFrames(tester);

      expect(_gridDelegate(tester).crossAxisCount, 2);
    });

    testWidgets('uses three columns under expanded layout', (tester) async {
      await tester.pumpWidget(
        _harness(
          layout: AppLayoutClass.expanded,
          child: ResponsiveListGrid<String>(
            items: const ['a', 'b', 'c'],
            keyOf: (item) => item,
            itemBuilder: (_, item) => SizedBox(child: Center(child: Text(item))),
          ),
        ),
      );
      await _pumpFrames(tester);

      expect(_gridDelegate(tester).crossAxisCount, 3);
    });

    testWidgets('honors a custom crossAxisCounts override', (tester) async {
      await tester.pumpWidget(
        _harness(
          layout: AppLayoutClass.expanded,
          child: ResponsiveListGrid<String>(
            crossAxisCounts: const ResponsiveGridColumns(compact: 2, medium: 3, expanded: 4),
            items: const ['a', 'b', 'c'],
            keyOf: (item) => item,
            itemBuilder: (_, item) => SizedBox(child: Center(child: Text(item))),
          ),
        ),
      );
      await _pumpFrames(tester);

      expect(_gridDelegate(tester).crossAxisCount, 4);
    });

    testWidgets('assigns stable ValueKeys derived from keyOf', (tester) async {
      await tester.pumpWidget(
        _harness(
          // Medium layout places both items in a single row so each cell is
          // within the viewport and materializes.
          layout: AppLayoutClass.medium,
          child: ResponsiveListGrid<String>(
            items: const ['alpha', 'beta'],
            keyOf: (item) => item,
            itemBuilder: (_, item) => SizedBox(height: 80, child: Text(item)),
          ),
        ),
      );
      await _pumpFrames(tester);

      expect(find.byKey(const ValueKey('responsive-grid-alpha')), findsOneWidget);
      expect(find.byKey(const ValueKey('responsive-grid-beta')), findsOneWidget);
    });
  });
}

SliverGridDelegateWithFixedCrossAxisCount _gridDelegate(WidgetTester tester) {
  final grid = tester.widget<GridView>(find.byType(GridView));
  return grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
}

Future<void> _pumpFrames(WidgetTester tester) async {
  for (var frame = 0; frame < 8; frame += 1) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Widget _harness({required AppLayoutClass layout, required Widget child}) {
  return ProviderScope(
    overrides: [appLayoutClassProvider.overrideWithValue(layout)],
    child: TranslationProvider(
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
            builder: (context, built) => Directionality(
              textDirection: localeData.locale == AppLocale.ar
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: FTheme(
                data: theme,
                child: FToaster(child: FTooltipGroup(child: built ?? const SizedBox.shrink())),
              ),
            ),
          );
        },
      ),
    ),
  );
}
