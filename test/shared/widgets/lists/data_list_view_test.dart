import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/app_spacing.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/lists/data_list_view.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  group('DataListView', () {
    testWidgets('virtualizes — only the visible items build', (tester) async {
      final built = <String>{};
      await tester.pumpWidget(
        _harness(
          child: DataListView<String>(
            items: [for (var i = 0; i < 50; i++) 'item-$i'],
            keyOf: (item) => item,
            itemBuilder: (_, item) {
              built.add(item);
              return SizedBox(height: 80, child: Center(child: Text(item)));
            },
          ),
        ),
      );
      await _pumpFrames(tester);

      expect(built.length, lessThan(50));
      expect(built, contains('item-0'));
      expect(built, isNot(contains('item-49')));
    });

    testWidgets('assigns stable ValueKeys derived from keyOf', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: DataListView<String>(
            items: const ['alpha', 'beta', 'gamma'],
            keyOf: (item) => item,
            itemBuilder: (_, item) => SizedBox(height: 80, child: Text(item)),
          ),
        ),
      );
      await _pumpFrames(tester);

      expect(find.byKey(const ValueKey('data-list-alpha')), findsOneWidget);
      expect(find.byKey(const ValueKey('data-list-beta')), findsOneWidget);
      expect(find.byKey(const ValueKey('data-list-gamma')), findsOneWidget);
    });

    testWidgets('renders the empty placeholder when items is empty', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: DataListView<String>(
            items: const [],
            keyOf: (item) => item,
            empty: const Text('empty-placeholder'),
            itemBuilder: (_, item) => Text(item),
          ),
        ),
      );
      await _pumpFrames(tester);

      expect(find.text('empty-placeholder'), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('inserts a separator between items when supplied', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: DataListView<String>(
            items: const ['alpha', 'beta', 'gamma'],
            keyOf: (item) => item,
            separator: const SizedBox(height: 4, key: ValueKey('sep')),
            itemBuilder: (_, item) => SizedBox(height: 80, child: Text(item)),
          ),
        ),
      );
      await _pumpFrames(tester);

      expect(find.byKey(const ValueKey('sep')), findsNWidgets(2));
    });

    testWidgets('applies the default repo spacing padding', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: DataListView<String>(
            items: const ['alpha'],
            keyOf: (item) => item,
            itemBuilder: (_, item) => SizedBox(height: 80, child: Text(item)),
          ),
        ),
      );
      await _pumpFrames(tester);

      final list = tester.widget<ListView>(find.byType(ListView));
      expect(
        list.padding,
        const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
      );
    });

    testWidgets('honors an explicit padding override', (tester) async {
      const padding = EdgeInsets.all(24);
      await tester.pumpWidget(
        _harness(
          child: DataListView<String>(
            items: const ['alpha'],
            keyOf: (item) => item,
            padding: padding,
            itemBuilder: (_, item) => SizedBox(height: 80, child: Text(item)),
          ),
        ),
      );
      await _pumpFrames(tester);

      expect(tester.widget<ListView>(find.byType(ListView)).padding, padding);
    });
  });
}

Future<void> _pumpFrames(WidgetTester tester) async {
  for (var frame = 0; frame < 8; frame += 1) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Widget _harness({required Widget child}) {
  return TranslationProvider(
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
  );
}
