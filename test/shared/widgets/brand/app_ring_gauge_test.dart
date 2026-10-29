import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/brand/app_ring_gauge.dart';

void main() {
  group('ringGaugeArcs', () {
    test('share draws one primary arc from the top over the track', () {
      final (start, sweep) = ringGaugeArcs(share: 0.25).single;
      expect(start, -90);
      expect(sweep, closeTo(90, 0.001));
    });

    test('share clamps into 0–1', () {
      expect(ringGaugeArcs(share: 2).single.$2, 360);
      expect(ringGaugeArcs(share: -1).single.$2, 0);
    });

    test('no share draws a full accent ring', () {
      final (start, sweep) = ringGaugeArcs().single;
      expect(start, -90);
      expect(sweep, 360);
    });

    test('count draws n segments joined by 5-unit gaps', () {
      final arcs = ringGaugeArcs(count: 4);
      expect(arcs, hasLength(4));

      const gapDegrees = 5 / 30 * 180 / math.pi;
      for (var index = 0; index < arcs.length - 1; index += 1) {
        final gap = arcs[index + 1].$1 - (arcs[index].$1 + arcs[index].$2);
        expect(gap, closeTo(gapDegrees, 0.001));
      }
      final totalSweep = arcs.map((arc) => arc.$2).reduce((a, b) => a + b);
      expect(totalSweep + gapDegrees * (arcs.length - 1), closeTo(360, 0.001));
      expect(arcs.first.$1, -90);
    });

    test('count wins when both share and count are given', () {
      expect(ringGaugeArcs(share: 0.5, count: 3), hasLength(3));
    });
  });

  group('AppRingGauge', () {
    testWidgets('renders a 72px ring beside the value and its label', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const AppRingGauge(share: 0.4, value: '74%', label: 'Events used'),
        ),
      );
      await tester.pump();

      expect(tester.getSize(find.byType(CustomPaint)), const Size(72, 72));
      expect(find.text('74%'), findsOneWidget);
      expect(find.text('Events used'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('paints the count branch without errors', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const AppRingGauge(count: 5, value: '8 of 10', label: 'Seats'),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('8 of 10'), findsOneWidget);
    });

    testWidgets('keeps the value and label in the normal text colors', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const AppRingGauge(share: 0.4, value: '74%', label: 'Events used'),
        ),
      );
      await tester.pump();

      final colors = generated.lightTheme.colors;
      expect(tester.widget<Text>(find.text('74%')).style!.color, colors.foreground);
      expect(
        tester.widget<Text>(find.text('Events used')).style!.color,
        colors.mutedForeground,
      );
    });

    testWidgets('sizes the value as the big-stat token, not a heading size', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          child: const AppRingGauge(share: 0.4, value: '74%', label: 'Events used'),
        ),
      );
      await tester.pump();

      // App type scale: big stat = 24 w500 tight, which the theme factory
      // resolves onto display.xl (display.xl2 is the 30px heading token).
      final valueStyle = tester.widget<Text>(find.text('74%')).style!;
      expect(valueStyle.fontSize, generated.lightTheme.typography.display.xl.fontSize);
      expect(valueStyle.fontWeight, FontWeight.w500);
      expect(
        valueStyle.letterSpacing,
        closeTo(-0.02 * generated.lightTheme.typography.display.xl.fontSize!, 0.001),
      );
    });
  });
}

Widget _harness({required Widget child}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: FTheme(
      data: generated.lightTheme,
      child: Scaffold(body: Center(child: child)),
    ),
  );
}
