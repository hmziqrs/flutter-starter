import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/brand_tokens.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/marks/cta_band.dart';
import 'package:starter/shared/widgets/rings/band_arcs.dart';
import 'package:starter/shared/widgets/rings/brand_rings.dart';

const String _heading = 'Start your next app with the boring parts done.';
const String _message = 'The starter ships with sign-in, settings and updates already built.';
const String _primary = 'Download for Mac';
const String _secondary = 'Read the blog';

CtaBand _band() => const CtaBand(
  heading: _heading,
  message: _message,
  primaryLabel: _primary,
  secondaryLabel: _secondary,
);

void main() {
  group('CtaBand', () {
    testWidgets('fills with oxide and flips the copy to on-orange', (tester) async {
      await tester.pumpWidget(_harness(child: _band()));

      final band = tester.widget<ColoredBox>(
        find.descendant(of: find.byType(CtaBand), matching: find.byType(ColoredBox)).first,
      );
      expect(band.color, AppBrandColors.light.oxide);
      expect(
        tester.widget<Text>(find.text(_heading)).style!.color,
        AppBrandColors.light.onOrange,
      );
      expect(
        tester.widget<Text>(find.text(_message)).style!.color,
        AppBrandColors.light.onOrange,
      );
    });

    testWidgets('flips to the dark on-orange over the dark oxide', (tester) async {
      await tester.pumpWidget(_harness(brightness: Brightness.dark, child: _band()));

      expect(
        tester
            .widget<ColoredBox>(
              find.descendant(of: find.byType(CtaBand), matching: find.byType(ColoredBox)).first,
            )
            .color,
        AppBrandColors.dark.oxide,
      );
      expect(
        tester.widget<Text>(find.text(_heading)).style!.color,
        AppBrandColors.dark.onOrange,
      );
    });

    testWidgets('fills the primary button with on-orange and its label with oxide', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(child: _band()));

      final primary = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(
        primary.style!.backgroundColor!.resolve(const <WidgetState>{}),
        AppBrandColors.light.onOrange,
      );
      expect(
        primary.style!.foregroundColor!.resolve(const <WidgetState>{}),
        AppBrandColors.light.oxide,
      );
      expect(primary.onPressed, isNull);
    });

    testWidgets('draws the outline button in on-orange with band arcs behind', (tester) async {
      await tester.pumpWidget(_harness(child: _band()));

      final outline = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      final side = outline.style!.side!.resolve(const <WidgetState>{})!;
      expect(side.color, AppBrandColors.light.onOrange.withValues(alpha: 0.45));

      expect(find.byType(BandArcs), findsOneWidget);
      final stack = tester.widget<Stack>(
        find.descendant(of: find.byType(CtaBand), matching: find.byType(Stack)),
      );
      final arcsIndex = stack.children.indexWhere((child) => child is Positioned);
      final contentIndex = stack.children.indexWhere((child) => child is Padding);
      expect(arcsIndex, 0, reason: 'arcs are the first child of the band stack');
      expect(arcsIndex, lessThan(contentIndex), reason: 'arcs sit under the content');
    });

    testWidgets('sits the band arcs out below md so rings never run behind text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_harness(child: _band()));

      expect(find.byType(BandArcs), findsNothing);
    });

    testWidgets('retunes the rings hairline to on-orange at 20% inside the band', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(child: _band()));

      final painter =
          tester
                  .widget<CustomPaint>(
                    find.descendant(of: find.byType(BandArcs), matching: find.byType(CustomPaint)),
                  )
                  .painter!
              as RingPicturePainter;
      expect(
        painter.lineColor,
        AppBrandColors.light.onOrange.withValues(alpha: 0.2),
      );
      expect(painter.accentColor, AppBrandColors.light.onOrange);
    });

    testWidgets('keeps the band square-edged and full width', (tester) async {
      await tester.pumpWidget(_harness(child: _band()));

      final size = tester.getSize(find.byType(CtaBand));
      expect(size.width, 800);
      final clip = tester.widget<ClipRect>(find.byType(ClipRect));
      expect(clip.clipBehavior, isNot(Clip.none));
    });
  });
}

Widget _harness({required Widget child, Brightness brightness = Brightness.light}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: FTheme(
      data: brightness == Brightness.dark ? generated.darkTheme : generated.lightTheme,
      child: Scaffold(
        body: SizedBox(width: 800, height: 800, child: child),
      ),
    ),
  );
}
