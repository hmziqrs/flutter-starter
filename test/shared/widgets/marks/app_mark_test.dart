import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/brand_tokens.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/marks/app_mark.dart';

final Finder _tile = find.descendant(
  of: find.byType(AppMark),
  matching: find.byWidgetPredicate(
    (widget) =>
        widget is DecoratedBox &&
        widget.decoration is BoxDecoration &&
        (widget.decoration as BoxDecoration).borderRadius != null,
  ),
);

final Finder _square = find.descendant(of: find.byType(AppMark), matching: find.byType(ColoredBox));

void main() {
  group('AppMark geometry', () {
    testWidgets('tiles the foreground with letters in the page color', (tester) async {
      await tester.pumpWidget(_harness(child: _mark()));

      final decoration = tester.widget<DecoratedBox>(_tile).decoration as BoxDecoration;
      expect(decoration.color, generated.lightTheme.colors.foreground);
      expect(decoration.borderRadius, BorderRadius.circular(20 * 0.22));
      expect(
        tester.widget<Text>(find.textContaining('Fx')).style!.color,
        generated.lightTheme.colors.background,
      );
    });

    testWidgets('draws letters at 0.42 of the tile in w600 tight', (tester) async {
      await tester.pumpWidget(_harness(child: _mark(size: 40)));

      final letters = tester.widget<Text>(find.textContaining('Fx')).style!;
      expect(letters.fontSize, closeTo(40 * 0.42, 0.001));
      expect(letters.fontWeight, FontWeight.w600);
      expect(letters.letterSpacing, closeTo(-0.02 * 40, 0.001));
    });

    testWidgets('draws the mark-square orange at 0.3 em of the letters', (tester) async {
      await tester.pumpWidget(_harness(child: _mark(size: 40)));

      final box = tester.widget<SizedBox>(
        find.ancestor(of: _square, matching: find.byType(SizedBox)).first,
      );
      expect(box.width, closeTo(40 * 0.42 * 0.3, 0.001));
      expect(box.height, closeTo(40 * 0.42 * 0.3, 0.001));
      expect(tester.widget<ColoredBox>(_square).color, AppBrandColors.light.markSquare);
    });

    testWidgets('keeps the gap between letters and square at 0.07 em of the letters', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(child: _mark(size: 40)));

      final padding = tester.widget<Padding>(
        find.ancestor(of: _square, matching: find.byType(Padding)).first,
      );
      expect(padding.padding, const EdgeInsetsDirectional.only(start: 40 * 0.42 * 0.07));
    });

    testWidgets('keeps the square bright orange in both modes', (tester) async {
      await tester.pumpWidget(_harness(brightness: Brightness.dark, child: _mark()));

      expect(tester.widget<ColoredBox>(_square).color, AppBrandColors.dark.markSquare);
      expect(
        (tester.widget<DecoratedBox>(_tile).decoration as BoxDecoration).color,
        generated.darkTheme.colors.foreground,
      );
    });

    testWidgets('announces squareLabel for the whole mark', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const AppMark(symbol: 'Fx', squareLabel: 'freeoxide mark'),
        ),
      );
      await tester.pump();

      expect(find.bySemanticsLabel('freeoxide mark'), findsOneWidget);
    });

    testWidgets('keeps the square inline on the letters baseline', (tester) async {
      await tester.pumpWidget(_harness(child: _mark(size: 56)));

      // The web recipe's square is inline at the baseline, not superscript:
      // its bottom edge lands on the letters' alphabetic baseline. The
      // painter replicates the paragraph's effective style (ambient default
      // merged under the widget style).
      final context = tester.element(find.textContaining('Fx'));
      final effectiveStyle = DefaultTextStyle.of(context).style.merge(
        tester.widget<Text>(find.textContaining('Fx')).style,
      );
      final painter = TextPainter(
        text: TextSpan(text: 'Fx', style: effectiveStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      final baseline = painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
      final lettersTop = tester.getTopLeft(find.textContaining('Fx')).dy;
      final squareBottom = tester.getRect(_square).bottom;
      expect(squareBottom - lettersTop, closeTo(baseline, 0.5));
    });
  });
}

AppMark _mark({double size = 20}) => AppMark(symbol: 'Fx', squareLabel: 'freeoxide', size: size);

Widget _harness({required Widget child, Brightness brightness = Brightness.light}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: FTheme(
      data: brightness == Brightness.dark ? generated.darkTheme : generated.lightTheme,
      child: Scaffold(body: Center(child: child)),
    ),
  );
}
