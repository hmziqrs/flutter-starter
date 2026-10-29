import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/brand_tokens.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/blocks/endpoint_card.dart';
import 'package:starter/shared/widgets/rings/status_ring.dart';

const List<double> _days = <double>[
  // A month of deliveries: two slow days, one down day, the rest clean.
  1, 1, 1, 1, 0.97, 1, 1, 1, 1, 1, //
  1, 0.5, 1, 1, 1, 1, 1, 1, 1, 1, //
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, //
];

AppEndpointCard _card() => const AppEndpointCard(
  url: 'https://api.paperplane.app/hooks/hookline',
  startLabel: 'Sep 14',
  days: _days,
  metrics: <AppEndpointMetric>[
    (label: 'First try', value: '99.4%'),
    (label: 'Median time', value: '182 ms'),
    (label: 'Retried', value: '41'),
  ],
  deliveries: <AppEndpointDelivery>[
    (event: 'invoice.paid', status: 200, at: '12:04:31'),
    (event: 'order.created', status: 503, at: '12:01:12'),
  ],
  primaryLabel: 'Send a test event',
  secondaryLabel: 'Pause',
);

void main() {
  group('AppEndpointCard', () {
    testWidgets('reads the last day: healthy with a green ring, 30 days', (tester) async {
      await tester.pumpWidget(_harness(child: SizedBox(width: 480, child: _card())));

      expect(find.text('Healthy'), findsOneWidget);
      expect(find.text('Last 30 days'), findsOneWidget);
      final ring = tester.widget<StatusRing>(find.byType(StatusRing));
      expect(ring.active, isTrue);
      expect(ring.stale, isFalse);
      expect(ring.color, generated.lightTheme.brand.success);
    });

    testWidgets('draws one bar per day with the retry band in warning', (tester) async {
      await tester.pumpWidget(_harness(child: SizedBox(width: 480, child: _card())));

      final boxes = tester
          .widgetList<DecoratedBox>(
            find.byWidgetPredicate((widget) {
              if (widget is! DecoratedBox) return false;
              final decoration = widget.decoration;
              return decoration is BoxDecoration && decoration.borderRadius != null;
            }),
          )
          .toList();
      expect(boxes, hasLength(_days.length));
      // The 0.97 day sits in the slow band: warning fill. The clean days are
      // the foreground at 25%.
      expect(
        boxes.where(
          (box) => (box.decoration as BoxDecoration).color == generated.lightTheme.brand.warning,
        ),
        hasLength(1),
      );
      expect(
        boxes.where(
          (box) =>
              (box.decoration as BoxDecoration).color ==
              generated.lightTheme.colors.foreground.withValues(alpha: 0.25),
        ),
        hasLength(_days.length - 2),
      );
    });

    testWidgets('splits the metrics with hairlines between equal columns', (tester) async {
      await tester.pumpWidget(_harness(child: SizedBox(width: 480, child: _card())));

      expect(find.text('First try'), findsOneWidget);
      expect(find.text('182 ms'), findsOneWidget);
      expect(find.text('41'), findsOneWidget);
      final columns = tester.widgetList<Expanded>(
        find.ancestor(of: find.text('99.4%'), matching: find.byType(Expanded)),
      );
      expect(columns.length, greaterThan(0));
    });

    testWidgets('lists deliveries with their status chips', (tester) async {
      await tester.pumpWidget(_harness(child: SizedBox(width: 480, child: _card())));

      expect(find.text('invoice.paid'), findsOneWidget);
      expect(find.text('200'), findsOneWidget);
      expect(find.text('503'), findsOneWidget);
    });

    testWidgets('keeps both footer actions tappable', (tester) async {
      var tested = false;
      var paused = false;
      await tester.pumpWidget(
        _harness(
          child: SizedBox(
            width: 480,
            child: AppEndpointCard(
              url: 'https://api.paperplane.app/hooks/hookline',
              days: const <double>[1],
              metrics: const <AppEndpointMetric>[(label: 'First try', value: '100%')],
              primaryLabel: 'Send a test event',
              onPrimary: () => tested = true,
              secondaryLabel: 'Pause',
              onSecondary: () => paused = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Send a test event'));
      // ForUI's tappable schedules 100ms timers on press; advance the fake
      // clock past them.
      await tester.pump(const Duration(milliseconds: 150));
      await tester.tap(find.text('Pause'));
      await tester.pump(const Duration(milliseconds: 150));
      expect(tested, isTrue);
      expect(paused, isTrue);
    });

    testWidgets('reads a failing last day: Failing and a stale ring', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const SizedBox(
            width: 480,
            child: AppEndpointCard(
              url: 'https://api.paperplane.app/hooks/hookline',
              days: <double>[0.4],
              metrics: <AppEndpointMetric>[(label: 'First try', value: '40%')],
              primaryLabel: 'Send a test event',
            ),
          ),
        ),
      );

      expect(find.text('Failing'), findsOneWidget);
      final ring = tester.widget<StatusRing>(find.byType(StatusRing));
      expect(ring.stale, isTrue);
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
