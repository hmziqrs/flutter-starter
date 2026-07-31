import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/refresh/app_refresh_indicator.dart';

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  group('AppRefreshIndicator', () {
    testWidgets('themes the spinner with the active accent color', (tester) async {
      await tester.pumpWidget(
        _harness(
          onRefresh: () async {},
          child: _scrollable(count: 20),
        ),
      );
      await _pumpFrames(tester);

      final indicator = tester.widget<RefreshIndicator>(find.byType(RefreshIndicator));
      expect(indicator.color, generated.lightTheme.colors.primary);
    });

    testWidgets('invokes onRefresh and completes on a pull gesture', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        _harness(
          onRefresh: () async {
            calls += 1;
          },
          child: _scrollable(count: 20),
        ),
      );
      await _pumpFrames(tester);

      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pump();
      await _pumpFrames(tester);

      expect(calls, greaterThanOrEqualTo(1));
    });

    testWidgets('renders the spinner transparent under reduce-motion', (tester) async {
      await tester.pumpWidget(
        _harness(
          disableAnimations: true,
          onRefresh: () async {},
          child: _scrollable(count: 20),
        ),
      );
      await _pumpFrames(tester);

      final indicator = tester.widget<RefreshIndicator>(find.byType(RefreshIndicator));
      expect(indicator.color, const Color(0x00000000));
      expect(indicator.backgroundColor, const Color(0x00000000));
    });

    testWidgets('renders localized ar copy under RTL without errors', (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.ar);
      await tester.pumpWidget(
        _harness(
          onRefresh: () async {},
          child: _scrollable(count: 5),
        ),
      );
      await _pumpFrames(tester);

      expect(find.byType(RefreshIndicator), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

Widget _scrollable({required int count}) {
  return ListView.builder(
    itemCount: count,
    itemBuilder: (_, index) => SizedBox(
      height: 80,
      child: Center(child: Text('item $index')),
    ),
  );
}

Future<void> _pumpFrames(WidgetTester tester) async {
  for (var frame = 0; frame < 8; frame += 1) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Widget _harness({
  required Future<void> Function() onRefresh,
  required Widget child,
  bool disableAnimations = false,
}) {
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
          home: Scaffold(
            body: AppRefreshIndicator(onRefresh: onRefresh, child: child),
          ),
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
