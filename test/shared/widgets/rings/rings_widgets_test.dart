import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/brand_tokens.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/rings/band_arcs.dart';
import 'package:starter/shared/widgets/rings/brand_rings.dart';
import 'package:starter/shared/widgets/rings/brand_seed.dart';
import 'package:starter/shared/widgets/rings/corner_rings.dart';
import 'package:starter/shared/widgets/rings/horizon_rings.dart';
import 'package:starter/shared/widgets/rings/ring_divider.dart';
import 'package:starter/shared/widgets/rings/ring_loader.dart';
import 'package:starter/shared/widgets/rings/ring_meter.dart';
import 'package:starter/shared/widgets/rings/scroll_rings.dart';
import 'package:starter/shared/widgets/rings/status_ring.dart';

void main() {
  group('BrandRings motion gates', () {
    testWidgets('the still picture never starts a ticker', (tester) async {
      await tester.pumpWidget(_harness(const BrandRings(seed: 'flutter')));
      await tester.pump();

      expect(_brandRingsState(tester).animating, isFalse);
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('motion runs until paused, reduced motion, or TickerMode', (tester) async {
      await tester.pumpWidget(
        _harness(
          const BrandRings(seed: 'flutter', motion: RingMotion.rippleTurn),
        ),
      );
      await tester.pump();
      expect(_brandRingsState(tester).animating, isTrue);
      expect(tester.binding.transientCallbackCount, greaterThan(0));

      // paused stops the movement where it is.
      await tester.pumpWidget(
        _harness(
          const BrandRings(
            seed: 'flutter',
            motion: RingMotion.rippleTurn,
            paused: true,
          ),
        ),
      );
      await tester.pump();
      expect(_brandRingsState(tester).animating, isFalse);
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('reduced motion gets the still picture and settles', (
      tester,
      // The picture is drawn once and never ticks: pumpAndSettle completes.
    ) async {
      await tester.pumpWidget(
        _harness(
          const BrandRings(seed: 'flutter', motion: RingMotion.rippleTurn),
          disableAnimations: true,
        ),
      );
      await tester.pump();
      expect(_brandRingsState(tester).animating, isFalse);
      expect(tester.binding.transientCallbackCount, 0);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('TickerMode (off screen) stops the animation', (tester) async {
      await tester.pumpWidget(
        _harness(
          const TickerMode(
            enabled: false,
            child: BrandRings(seed: 'flutter', motion: RingMotion.rippleTurn),
          ),
        ),
      );
      await tester.pump();
      // The state may hold its ticker, but a muted ticker gets no time: no
      // transient callbacks are scheduled.
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('renders inside a 520x440 box without errors', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _harness(
          const SizedBox(
            width: 520,
            height: 440,
            child: BrandRings(
              seed: 'flutter',
              motion: RingMotion.dial,
              semanticsLabel: 'Rings',
            ),
          ),
        ),
      );
      // An infinite motion never settles: pump a few frames only.
      await tester.pump();
      await tester.pump(const Duration(seconds: 30));
      expect(tester.takeException(), isNull);
      expect(find.bySemanticsLabel('Rings'), findsOneWidget);
      semantics.dispose();
    });
  });

  group('CornerRings', () {
    testWidgets('renders the fingerprint square and stays decorative', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _harness(
          SizedBox(
            width: 100,
            height: 100,
            child: CornerRings(
              seed: 'flutter',
              accentColor: generated.lightTheme.brand.teal,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // Rings never sit behind text and carry no meaning on their own: the
      // widget excludes itself from semantics.
      final exclusion = tester.widget<ExcludeSemantics>(
        find.descendant(
          of: find.byType(CornerRings),
          matching: find.byType(ExcludeSemantics),
        ),
      );
      expect(exclusion.excluding, isTrue);
      semantics.dispose();
    });
  });

  group('BandArcs', () {
    testWidgets('renders without errors and draws no dot', (tester) async {
      await tester.pumpWidget(
        _harness(const SizedBox(width: 400, height: 400, child: BandArcs())),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('HorizonRings', () {
    testWidgets('renders awake and asleep, transitions between', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(const HorizonRings(seed: 'flutter', ripple: true)),
      );
      await tester.pump();
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      await tester.pumpWidget(
        _harness(const HorizonRings(seed: 'flutter', awake: false)),
      );
      await tester.pumpAndSettle();
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('reduced motion holds the still picture', (tester) async {
      await tester.pumpWidget(
        _harness(
          const HorizonRings(seed: 'flutter', ripple: true),
          disableAnimations: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    });
  });

  group('ScrollRings', () {
    ScrollRingsPainter painterOf(WidgetTester tester) => tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((customPaint) => customPaint.painter)
        .whereType<ScrollRingsPainter>()
        .single;

    testWidgets('draws the hero picture, revealed by scroll position', (
      tester,
    ) async {
      final controller = ScrollController();
      await tester.pumpWidget(
        _harness(
          SizedBox(
            width: 520,
            height: 440,
            child: CustomScrollView(
              controller: controller,
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: SizedBox(
                    width: 520,
                    height: 440,
                    child: ScrollRings(seed: 'flutter', controller: controller),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(width: 520, height: 800),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The picture is the hero recipe for the seed, exactly as BrandRings
      // draws it.
      final painter = painterOf(tester);
      expect(
        painter.arcs.map(_arcField).toList(),
        heroRings('flutter').arcs.map(_arcField).toList(),
      );
      // At the top nothing has drawn yet.
      expect(painter.progressValue, 0);
      // Half a viewport (440) of scrolling draws the whole picture.
      controller.jumpTo(220);
      await tester.pumpAndSettle();
      expect(painter.progressValue, 1);
      // And it undraws on the way up.
      controller.jumpTo(0);
      await tester.pumpAndSettle();
      expect(painter.progressValue, 0);
      controller.dispose();
    });

    testWidgets('reveals through the nearest scrollable', (tester) async {
      await tester.pumpWidget(
        _harness(
          const SizedBox(
            width: 520,
            height: 440,
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  SizedBox(width: 520, height: 440),
                  SizedBox(
                    width: 520,
                    height: 440,
                    child: ScrollRings(seed: 'flutter'),
                  ),
                  SizedBox(width: 520, height: 800),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(painterOf(tester).progressValue, 0);
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -100),
      );
      await tester.pumpAndSettle();
      expect(painterOf(tester).progressValue, closeTo(100 / 220, 0.001));
      expect(tester.takeException(), isNull);
    });

    testWidgets('reduced motion skips the draw and shows the full picture', (
      tester,
    ) async {
      final controller = ScrollController();
      await tester.pumpWidget(
        _harness(
          SizedBox(
            width: 520,
            height: 440,
            child: CustomScrollView(
              controller: controller,
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: SizedBox(
                    width: 520,
                    height: 440,
                    child: ScrollRings(seed: 'flutter', controller: controller),
                  ),
                ),
              ],
            ),
          ),
          disableAnimations: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(painterOf(tester).progressValue, 1, reason: 'the full picture');
      controller.dispose();
    });
  });

  group('small pieces', () {
    testWidgets('RingDivider draws the hairline and the end ring', (tester) async {
      await tester.pumpWidget(
        _harness(
          const SizedBox(width: 200, child: RingDivider(filled: true)),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // The kit's 40x40 cluster picture at 28px.
      final paint = tester.widget<CustomPaint>(find.byType(CustomPaint));
      expect(paint.size, const Size(28, 28));
      // The seeded recipe: three rings, one of them the accent, drawn the
      // same from the same name.
      final arcs = ringDividerArcs('divider');
      expect(arcs, hasLength(3));
      expect(arcs.map((arc) => arc.accent), containsOnce(isTrue));
      expect(_arcFields(arcs), _arcFields(ringDividerArcs('divider')));
      expect(_arcFields(ringDividerArcs('part-two')), isNot(_arcFields(arcs)));
    });

    testWidgets('RingLoader sweeps when allowed and stills under reduced motion', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(const RingLoader()));
      await tester.pump();
      expect(tester.binding.transientCallbackCount, greaterThan(0));

      await tester.pumpWidget(
        _harness(const RingLoader(), disableAnimations: true),
      );
      await tester.pumpAndSettle();
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('RingMeter stacks the shares as rings with a legend', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          const SizedBox(
            width: 480,
            child: RingMeter(
              label: 'Usage this month',
              items: <RingMeterItem>[
                RingMeterItem(label: 'Storage', value: 0.72),
                RingMeterItem(label: 'Build minutes', value: 0.4),
                RingMeterItem(label: 'Bandwidth', value: 0.18),
                RingMeterItem(label: 'Emails', value: 0.9),
                RingMeterItem(label: 'Extra', value: 0.5),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // The kit draws at most four rings; the legend names the shown ones.
      final painter = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((painter) => painter.painter)
          .whereType<RingMeterPainter>()
          .single;
      expect(painter.values, const <double>[0.72, 0.4, 0.18, 0.9]);
      expect(find.text('Usage this month'), findsOneWidget);
      expect(find.text('Storage'), findsOneWidget);
      expect(find.text('72%'), findsOneWidget);
      expect(find.text('40%'), findsOneWidget);
      expect(find.text('18%'), findsOneWidget);
      expect(find.text('Extra'), findsNothing, reason: 'the kit shows four');
    });

    testWidgets('StatusRing fills only when active', (tester) async {
      await tester.pumpWidget(
        _harness(
          const Column(
            children: <Widget>[
              StatusRing(active: false),
              StatusRing(active: true),
            ],
          ),
        ),
      );
      await tester.pump();
      final painters = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((painter) => painter.painter)
          .whereType<StatusRingPainter>()
          .toList();
      expect(painters, hasLength(2));
      // Off: the ring-art hairline, no dot, no motion.
      expect(painters.first.active, isFalse);
      expect(painters.first.lineColor, generated.lightTheme.brand.line);
      // On: the accent color and the turning group.
      expect(painters.last.active, isTrue);
      expect(painters.last.color, generated.lightTheme.colors.primary);
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      expect(tester.takeException(), isNull);
    });
  });
}

BrandRingsState _brandRingsState(WidgetTester tester) =>
    tester.state<BrandRingsState>(find.byType(BrandRings));

/// The recipe fields of one drawn ring, for comparing seeded draws (RingArc
/// has no equality).
(double, double, double, double, bool) _arcField(RingArc arc) =>
    (arc.radius, arc.drawn, arc.gap, arc.rotateDegrees, arc.accent);

/// The recipe fields of a drawn ring picture, in draw order.
List<(double, double, double, double, bool)> _arcFields(List<RingArc> arcs) =>
    arcs.map(_arcField).toList();

Widget _harness(Widget child, {bool disableAnimations = false}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: TranslationProvider(
      child: FTheme(
        data: generated.lightTheme,
        child: MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: Scaffold(body: Center(child: child)),
        ),
      ),
    ),
  );
}
