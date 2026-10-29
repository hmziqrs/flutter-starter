import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/brand_tokens.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/brand/app_ring_marker.dart';
import 'package:starter/shared/widgets/rings/band_arcs.dart';
import 'package:starter/shared/widgets/rings/brand_rings.dart';
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
    HorizonRingsPainter painterOf(WidgetTester tester) => tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((customPaint) => customPaint.painter)
        .whereType<HorizonRingsPainter>()
        .single;

    testWidgets('reveals with scroll position', (tester) async {
      final controller = ScrollController();
      await tester.pumpWidget(
        _harness(
          SizedBox(
            width: 600,
            height: 320,
            child: CustomScrollView(
              controller: controller,
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: SizedBox(
                    width: 600,
                    height: 320,
                    child: ScrollRings(seed: 'flutter', controller: controller),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(width: 600, height: 800),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // At the top nothing has revealed yet.
      expect(painterOf(tester).revealValue, 0);
      // Half a viewport of scrolling brings the whole picture in.
      controller.jumpTo(160);
      await tester.pumpAndSettle();
      expect(painterOf(tester).revealValue, 1);
      // And it goes back out on the way up.
      controller.jumpTo(0);
      await tester.pumpAndSettle();
      expect(painterOf(tester).revealValue, 0);
      controller.dispose();
    });

    testWidgets('reveals through the nearest scrollable', (tester) async {
      await tester.pumpWidget(
        _harness(
          const SizedBox(
            width: 600,
            height: 320,
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  SizedBox(width: 600, height: 320),
                  SizedBox(
                    width: 600,
                    height: 320,
                    child: ScrollRings(seed: 'flutter'),
                  ),
                  SizedBox(width: 600, height: 800),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(painterOf(tester).revealValue, 0);
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -100),
      );
      await tester.pumpAndSettle();
      expect(painterOf(tester).revealValue, closeTo(100 / 160, 0.001));
      expect(tester.takeException(), isNull);
    });

    testWidgets('reduced motion skips the reveal entirely', (tester) async {
      final controller = ScrollController();
      await tester.pumpWidget(
        _harness(
          SizedBox(
            width: 600,
            height: 320,
            child: CustomScrollView(
              controller: controller,
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: SizedBox(
                    width: 600,
                    height: 320,
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
      expect(painterOf(tester).revealValue, 1, reason: 'the still picture');
      controller.dispose();
    });
  });

  group('small pieces', () {
    testWidgets('RingDivider draws the hairline and the end ring', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          const SizedBox(width: 200, child: RingDivider(filled: true)),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final marker = tester.widget<AppRingMarker>(find.byType(AppRingMarker));
      expect(marker.filled, isTrue);
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

    testWidgets('RingMeter draws the value arc', (tester) async {
      await tester.pumpWidget(_harness(const RingMeter(value: 0.4)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(CustomPaint)), const Size(36, 36));
      final painter =
          tester.widget<CustomPaint>(find.byType(CustomPaint)).painter! as RingMeterPainter;
      expect(painter.share, 0.4);
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
      await tester.pumpAndSettle();
      final markers = tester.widgetList<AppRingMarker>(find.byType(AppRingMarker)).toList();
      expect(markers.first.filled, isFalse);
      expect(markers.last.filled, isTrue);
      expect(markers.last.color, generated.lightTheme.colors.primary);
    });
  });
}

BrandRingsState _brandRingsState(WidgetTester tester) =>
    tester.state<BrandRingsState>(find.byType(BrandRings));

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
