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

    test('count draws n segments joined by 5-unit gaps, one wrapping past the top', () {
      final arcs = ringGaugeArcs(count: 4);
      expect(arcs, hasLength(4));

      // The brand dash recipe: each segment is a 5-unit gap shorter than its
      // nth of the circle, and the closing gap wraps to the starting point.
      const gapDegrees = 5 / 30 * 180 / math.pi;
      final segmentSweep = 360 / arcs.length - gapDegrees;
      for (var index = 0; index < arcs.length; index += 1) {
        expect(arcs[index].$2, closeTo(segmentSweep, 0.001));
        final expectedStart = -90.0 + index * (segmentSweep + gapDegrees);
        expect(arcs[index].$1, closeTo(expectedStart, 0.001));
      }
      final totalSweep = arcs.map((arc) => arc.$2).reduce((a, b) => a + b);
      expect(totalSweep + gapDegrees * arcs.length, closeTo(360, 0.001));
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

    testWidgets('sizes the value on the gauge recipe, not the StatCard big stat', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          child: const AppRingGauge(share: 0.4, value: '74%', label: 'Events used'),
        ),
      );
      await tester.pump();

      // BRAND.md s7 / ring-stats.svelte:24: text-[1.75rem] leading-[1.05]
      // font-medium tracking-[-0.03em] — 28px at the default display scale,
      // sized as 28/24 of the display.xl token so it rides the display scale.
      // The 24/-0.02 big stat belongs to StatCard, not the ring gauge.
      final valueStyle = tester.widget<Text>(find.text('74%')).style!;
      final base = generated.lightTheme.typography.display.xl.fontSize!;
      expect(valueStyle.fontSize, closeTo(base * 28 / 24, 0.001));
      expect(valueStyle.fontWeight, FontWeight.w500);
      expect(valueStyle.letterSpacing, closeTo(-0.03 * base * 28 / 24, 0.001));
      expect(valueStyle.height, 1.05);
    });

    testWidgets('gaps the value, label, and ring like the brand block', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const AppRingGauge(share: 0.4, value: '74%', label: 'Events used'),
        ),
      );
      await tester.pump();

      // ring-stats.svelte: flex-col gap-1 between value and label, and the
      // gauge story's gap-4 between ring and text by default.
      final valueBottom = tester.getBottomLeft(find.text('74%')).dy;
      final labelTop = tester.getTopLeft(find.text('Events used')).dy;
      expect(labelTop - valueBottom, 4);

      final ring = find.descendant(
        of: find.byType(AppRingGauge),
        matching: find.byType(CustomPaint),
      );
      expect(tester.getTopLeft(find.text('74%')).dx - tester.getTopRight(ring.first).dx, 16);
    });

    testWidgets('ring-stats sits tighter: 18 between ring and text', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const AppRingGauge(
            share: 0.4,
            value: '74%',
            label: 'Events used',
            spacing: 18,
          ),
        ),
      );
      await tester.pump();

      final ring = find.descendant(
        of: find.byType(AppRingGauge),
        matching: find.byType(CustomPaint),
      );
      expect(tester.getTopLeft(find.text('74%')).dx - tester.getTopRight(ring.first).dx, 18);
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
