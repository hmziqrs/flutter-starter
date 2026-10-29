import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/brand_tokens.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/blocks/usage_meter.dart';

void main() {
  group('AppUsageMeter', () {
    testWidgets('runs primary below the warning level, warning from it, destructive at the limit', (
      tester,
    ) async {
      final light = generated.lightTheme;

      AppUsageMeter meter(double share) => AppUsageMeter(
        label: 'Events this month',
        used: 10000 * share,
        limit: 10000,
        unit: 'events',
      );

      expect(meter(0.742).fillColor(light), light.colors.primary);
      expect(meter(0.8).fillColor(light), light.brand.warning);
      expect(meter(1).fillColor(light), light.brand.destructive);
    });

    testWidgets('keeps the bar honest at and over the limit, with the caller\u2019s message', (
      tester,
    ) async {
      final light = generated.lightTheme;
      await tester.pumpWidget(
        _harness(
          child: const AppUsageMeter(
            label: 'Events this month',
            used: 12420,
            limit: 10000,
            unit: 'events',
            limitMessage: 'You\u2019ve used every event this month.',
          ),
        ),
      );

      expect(tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value, 1);
      expect(find.text('12,420 / 10,000 events'), findsOneWidget);
      expect(find.text('You\u2019ve used every event this month.'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('You\u2019ve used every event this month.')).style!.color,
        light.brand.destructive,
      );
    });

    testWidgets('a meter with no limit draws no bar', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const AppUsageMeter(
            label: 'Projects',
            used: 12,
            limit: null,
            unit: 'projects',
            noLimitText: 'No limit',
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.text('12 projects \u00b7 No limit'), findsOneWidget);
    });

    testWidgets('the value words come from the caller when given', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const AppUsageMeter(
            label: 'Seats',
            used: 8,
            limit: 10,
            unit: 'seats',
            valueText: '8 of 10 seats',
          ),
        ),
      );
      expect(find.text('8 of 10 seats'), findsOneWidget);
    });

    test('share clamps to the drawable range', () {
      const meter = AppUsageMeter(label: 'Events', used: 12420, limit: 10000, unit: 'events');
      expect(meter.share, 1);
      expect(
        const AppUsageMeter(label: 'Events', used: 0, limit: 10000, unit: 'events').share,
        0,
      );
      expect(
        const AppUsageMeter(label: 'Events', used: 5, limit: null, unit: 'events').share,
        0,
      );
    });
  });
}

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
