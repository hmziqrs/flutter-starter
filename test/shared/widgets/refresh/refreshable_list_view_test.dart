import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/refresh/refreshable_list_view.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  group('RefreshableListView', () {
    testWidgets('virtualizes — only the visible items build', (tester) async {
      final built = <String>{};
      await tester.pumpWidget(
        _harness(
          child: RefreshableListView<String>(
            items: [for (var i = 0; i < 50; i++) 'item-$i'],
            keyOf: (item) => item,
            onRefresh: () async {},
            itemBuilder: (_, item) {
              built.add(item);
              return SizedBox(
                height: 80,
                child: Center(child: Text(item)),
              );
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
          child: RefreshableListView<String>(
            items: const ['alpha', 'beta', 'gamma'],
            keyOf: (item) => item,
            onRefresh: () async {},
            itemBuilder: (_, item) => SizedBox(height: 80, child: Text(item)),
          ),
        ),
      );
      await _pumpFrames(tester);

      expect(find.byKey(const ValueKey('refreshable-alpha')), findsOneWidget);
      expect(find.byKey(const ValueKey('refreshable-beta')), findsOneWidget);
      expect(find.byKey(const ValueKey('refreshable-gamma')), findsOneWidget);
    });

    testWidgets('invokes onRefresh and dismisses on Future completion', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        _harness(
          child: RefreshableListView<String>(
            items: const ['alpha', 'beta', 'gamma'],
            keyOf: (item) => item,
            onRefresh: () async {
              calls += 1;
            },
            itemBuilder: (_, item) => SizedBox(height: 80, child: Text(item)),
          ),
        ),
      );
      await _pumpFrames(tester);

      await tester.fling(find.byType(ListView).first, const Offset(0, 300), 1000);
      await tester.pump();
      await _pumpFrames(tester);

      expect(calls, greaterThanOrEqualTo(1));
    });

    testWidgets('mounts the Cupertino control when style is cupertino', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: RefreshableListView<String>(
            style: RefreshIndicatorStyle.cupertino,
            items: const ['alpha', 'beta'],
            keyOf: (item) => item,
            onRefresh: () async {},
            itemBuilder: (_, item) => SizedBox(height: 80, child: Text(item)),
          ),
        ),
      );
      await _pumpFrames(tester);

      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(find.byType(RefreshIndicator), findsNothing);
    });

    testWidgets(
      'falls back to the Material indicator under reduce-motion even for cupertino style',
      (tester) async {
        await tester.pumpWidget(
          _harness(
            disableAnimations: true,
            child: RefreshableListView<String>(
              style: RefreshIndicatorStyle.cupertino,
              items: const ['alpha', 'beta'],
              keyOf: (item) => item,
              onRefresh: () async {},
              itemBuilder: (_, item) => SizedBox(height: 80, child: Text(item)),
            ),
          ),
        );
        await _pumpFrames(tester);

        expect(find.byType(RefreshIndicator), findsOneWidget);
        expect(find.byType(CupertinoSliverRefreshControl), findsNothing);
      },
    );

    testWidgets('renders the empty placeholder and stays refreshable', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        _harness(
          child: RefreshableListView<String>(
            items: const [],
            keyOf: (item) => item,
            onRefresh: () async {
              calls += 1;
            },
            empty: const Text('empty-placeholder'),
            itemBuilder: (_, item) => Text(item),
          ),
        ),
      );
      await _pumpFrames(tester);

      expect(find.text('empty-placeholder'), findsOneWidget);
      expect(find.byType(RefreshIndicator), findsOneWidget);

      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pump();
      await _pumpFrames(tester);

      expect(calls, greaterThanOrEqualTo(1));
    });

    testWidgets('inserts a separator between items when supplied', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: RefreshableListView<String>(
            items: const ['alpha', 'beta'],
            keyOf: (item) => item,
            onRefresh: () async {},
            separator: const SizedBox(height: 4, key: ValueKey('sep')),
            itemBuilder: (_, item) => SizedBox(height: 80, child: Text(item)),
          ),
        ),
      );
      await _pumpFrames(tester);

      expect(find.byKey(const ValueKey('sep')), findsOneWidget);
    });
  });
}

Future<void> _pumpFrames(WidgetTester tester) async {
  for (var frame = 0; frame < 8; frame += 1) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Widget _harness({required Widget child, bool disableAnimations = false}) {
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
          builder: (context, built) {
            final content = Directionality(
              textDirection: localeData.locale == AppLocale.ar
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: FTheme(
                data: theme,
                child: FToaster(child: FTooltipGroup(child: built ?? const SizedBox.shrink())),
              ),
            );
            if (!disableAnimations) {
              return content;
            }
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: content,
            );
          },
        );
      },
    ),
  );
}
