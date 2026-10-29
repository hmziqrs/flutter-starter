import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/brand_tokens.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/blocks/metric_trend.dart';

void main() {
  group('AppMetricTrend', () {
    testWidgets('rising visitors is good news: green with an up arrow', (tester) async {
      final light = generated.lightTheme;
      await tester.pumpWidget(
        _harness(
          child: const AppMetricTrend(change: 0.12, comparison: 'vs last 30 days'),
        ),
      );

      expect(find.byIcon(FLucideIcons.arrowUpRight), findsOneWidget);
      expect(_textColor(tester, '+12%'), light.brand.success);
    });

    testWidgets('color follows meaning, not direction: a rising bounce rate is red', (
      tester,
    ) async {
      final light = generated.lightTheme;
      await tester.pumpWidget(
        _harness(
          child: const AppMetricTrend(change: 0.12, good: AppTrendGood.down),
        ),
      );

      expect(
        find.byIcon(FLucideIcons.arrowUpRight),
        findsOneWidget,
        reason: 'arrow keeps direction',
      );
      expect(_textColor(tester, '+12%'), light.brand.destructive);
    });

    testWidgets('a falling bounce rate is green with a down arrow', (tester) async {
      final light = generated.lightTheme;
      await tester.pumpWidget(
        _harness(
          child: const AppMetricTrend(change: -0.03, good: AppTrendGood.down),
        ),
      );

      expect(find.byIcon(FLucideIcons.arrowDownRight), findsOneWidget);
      expect(_textColor(tester, '\u22123%'), light.brand.success);
    });

    testWidgets('words always carry a sign, using a true minus', (tester) async {
      await tester.pumpWidget(
        _harness(child: const AppMetricTrend(change: -2.8, format: AppTrendFormat.points)),
      );
      expect(find.text('\u22122.8 points'), findsOneWidget);
    });

    testWidgets('no change reads muted with the caller\u2019s words and a minus icon', (
      tester,
    ) async {
      final light = generated.lightTheme;
      await tester.pumpWidget(
        _harness(
          child: const AppMetricTrend(change: 0, noChangeLabel: 'No change'),
        ),
      );

      expect(find.byIcon(FLucideIcons.minus), findsOneWidget);
      expect(_textColor(tester, 'No change'), light.colors.mutedForeground);
    });

    testWidgets('neither direction reads muted in both directions', (tester) async {
      final light = generated.lightTheme;
      await tester.pumpWidget(
        _harness(
          child: const AppMetricTrend(change: 0.4, good: AppTrendGood.neither),
        ),
      );
      expect(_textColor(tester, '+40%'), light.colors.mutedForeground);
    });

    testWidgets('number format groups digits', (tester) async {
      await tester.pumpWidget(
        _harness(child: const AppMetricTrend(change: 1234, format: AppTrendFormat.number)),
      );
      expect(find.text('+1,234'), findsOneWidget);
    });

    test('meaning resolves by good news, not by motion', () {
      // Rising visitors: up is the good way.
      expect(
        const AppMetricTrend(change: 0.12).meaning,
        AppTrendGood.up,
      );
      // Rising load time: up is the bad way.
      expect(
        const AppMetricTrend(change: 0.12, good: AppTrendGood.down).meaning,
        AppTrendGood.down,
      );
      // Falling load time: down is the good way.
      expect(
        const AppMetricTrend(change: -0.1, good: AppTrendGood.down).meaning,
        AppTrendGood.up,
      );
      // Flat, or neither way is good: no meaning.
      expect(const AppMetricTrend(change: 0).meaning, AppTrendGood.neither);
      expect(
        const AppMetricTrend(change: -0.2, good: AppTrendGood.neither).meaning,
        AppTrendGood.neither,
      );
    });

    test('screen readers hear the direction spelled out', () {
      // APP-BLOCKS.md MetricTrend: "Up 12% vs last 30 days", not a sign to
      // decode.
      expect(
        const AppMetricTrend(change: 0.12, comparison: 'vs last 30 days').semanticsText,
        'Up 12% vs last 30 days',
      );
      expect(
        const AppMetricTrend(change: -0.03, comparison: 'bounce rate').semanticsText,
        'Down 3% bounce rate',
      );
      expect(
        const AppMetricTrend(
          change: 0,
          noChangeLabel: 'No change',
          comparison: 'uptime',
        ).semanticsText,
        'No change uptime',
      );
      expect(
        const AppMetricTrend(change: -2.8, format: AppTrendFormat.points).semanticsText,
        'Down 2.8 points',
      );
    });
  });
}

Color _textColor(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style!.color!;

Widget _harness({required Widget child, Brightness brightness = Brightness.light}) {
  final theme = brightness == Brightness.dark ? generated.darkTheme : generated.lightTheme;
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: FTheme(
      data: theme,
      child: Scaffold(body: Center(child: child)),
    ),
  );
}
