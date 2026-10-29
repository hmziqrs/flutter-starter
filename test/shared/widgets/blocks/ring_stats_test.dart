import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/blocks/ring_stats.dart';
import 'package:starter/shared/widgets/brand/app_ring_gauge.dart';

void main() {
  group('AppRingStats', () {
    testWidgets('one column below 640, like the brand grid', (tester) async {
      await tester.pumpWidget(
        _harness(
          width: 390,
          child: const AppRingStats(stats: _stats),
        ),
      );

      // `grid gap-8 sm:grid-cols-3` — no columns until sm, so a single column.
      final gauges = _rects(tester);
      expect(gauges, hasLength(3));
      for (final gauge in gauges) {
        expect(gauge.left, gauges.first.left);
      }
      expect(gauges[1].top - gauges[0].top, greaterThan(72));
      expect(gauges[2].top - gauges[1].top, greaterThan(72));
    });

    testWidgets('three columns from 640 with 32px gutters', (tester) async {
      await tester.pumpWidget(
        _harness(
          width: 800,
          child: const AppRingStats(stats: _stats),
        ),
      );

      final gauges = _rects(tester);
      expect(gauges, hasLength(3));
      for (final gauge in gauges) {
        expect(gauge.top, gauges.first.top);
      }
      expect(gauges[1].left - gauges[0].left, greaterThan(72));
      expect(gauges[2].left - gauges[1].left, greaterThan(72));
    });

    testWidgets('sits the text 18 from the ring, the brand gap-4.5', (tester) async {
      await tester.pumpWidget(
        _harness(
          width: 800,
          child: const AppRingStats(stats: _stats),
        ),
      );

      expect(
        tester.widgetList<AppRingGauge>(find.byType(AppRingGauge)).map((gauge) => gauge.spacing),
        everyElement(18),
      );
    });
  });
}

const _stats = <AppRingStat>[
  (value: '100%', label: 'Open source', share: 1, count: null),
  (value: '90%+', label: 'Tests that pass', share: 0.9, count: null),
  (value: '5', label: 'Rounds of review', share: null, count: 5),
];

/// Rects of every gauge in pump order (WidgetTester has no bulk rect getter).
List<Rect> _rects(WidgetTester tester) => find
    .byType(AppRingGauge)
    .evaluate()
    .map((element) => tester.getRect(find.byWidget(element.widget)))
    .toList();

Widget _harness({required double width, required Widget child}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: FTheme(
      data: generated.lightTheme,
      child: Scaffold(
        body: Center(
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  );
}
