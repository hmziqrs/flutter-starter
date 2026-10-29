import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/shared/adaptive/app_interaction_policy.dart';
import 'package:starter/shared/theme/brand_tokens.dart';
import 'package:starter/shared/theme/forui_theme_factory.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/brand/app_wordmark.dart';

void main() {
  group('AppWordmark', () {
    testWidgets('renders the name semibold with tight tracking', (tester) async {
      await tester.pumpWidget(_harness(child: const AppWordmark(name: 'freeoxide')));
      await tester.pump();

      // The inline square span appends an object-replacement character to
      // the rendered plain text, so match by containment.
      final style = tester.widget<Text>(find.textContaining('freeoxide')).style!;
      expect(style.fontSize, 18);
      expect(style.fontWeight, FontWeight.w600);
      expect(style.letterSpacing, closeTo(-0.02 * 18, 0.001));
      expect(style.color, generated.lightTheme.colors.foreground);
    });

    testWidgets('ends in a trailing orange square sized from the font', (tester) async {
      await tester.pumpWidget(_harness(child: const AppWordmark(name: 'freeoxide')));
      await tester.pump();

      final square = _squareBox(tester);
      expect((square.decoration as BoxDecoration).color, AppBrandColors.light.markSquare);
      final squareSize = tester.getSize(find.byWidget(square));
      expect(squareSize.width, closeTo(18 * 0.36, 0.001));
      expect(squareSize.height, closeTo(18 * 0.36, 0.001));
    });

    testWidgets('showSquare false omits the square', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const AppWordmark(
            name: 'freeoxide',
            fontSize: 24,
            showSquare: false,
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is DecoratedBox &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color == AppBrandColors.light.markSquare,
        ),
        findsNothing,
      );
      expect(tester.widget<Text>(find.text('freeoxide')).style!.fontSize, 24);
    });

    testWidgets('renders the maker line muted at 0.78em', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const AppWordmark(name: 'freeoxide', makerLine: 'by hmziq'),
        ),
      );
      await tester.pump();

      final style = tester.widget<Text>(find.text('by hmziq')).style!;
      expect(style.fontSize, closeTo(18 * 0.78, 0.001));
      expect(style.color, generated.lightTheme.colors.mutedForeground);
    });

    testWidgets('scales the square with fontSize', (tester) async {
      await tester.pumpWidget(
        _harness(child: const AppWordmark(name: 'freeoxide', fontSize: 33)),
      );
      await tester.pump();

      final square = _squareBox(tester);
      final squareSize = tester.getSize(find.byWidget(square));
      expect(squareSize.width, closeTo(33 * 0.36, 0.001));
      expect(squareSize.height, closeTo(33 * 0.36, 0.001));
    });

    testWidgets('sits the square inline on the alphabetic baseline', (tester) async {
      await tester.pumpWidget(_harness(child: const AppWordmark(name: 'freeoxide')));
      await tester.pump();

      // The square rides inline in the name's text flow: its bottom edge
      // must land exactly on the name's alphabetic baseline. (A baseline
      // flex pins baseline-less children to the row's top edge instead.)
      final name = find.textContaining('freeoxide');
      final context = tester.element(name);
      final effectiveStyle = DefaultTextStyle.of(context).style.merge(
        tester.widget<Text>(name).style,
      );
      final painter = TextPainter(
        text: TextSpan(text: 'freeoxide', style: effectiveStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      final baseline = painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
      final textTop = tester.getTopLeft(name).dy;
      final squareBottom = tester.getRect(find.byWidget(_squareBox(tester))).bottom;
      expect(squareBottom - textTop, closeTo(baseline, 0.5));
    });

    testWidgets('keeps the baseline square with real Onest metrics in the production theme', (
      tester,
    ) async {
      // The bundled Onest faces, loaded so the paragraph lays out with the
      // brand typeface's real ascent/descent instead of the test font.
      final loader = FontLoader('Onest')
        ..addFont(rootBundle.load('assets/fonts/Onest/onest-latin-400-normal.ttf'))
        ..addFont(rootBundle.load('assets/fonts/Onest/onest-latin-500-normal.ttf'))
        ..addFont(rootBundle.load('assets/fonts/Onest/onest-latin-600-normal.ttf'));
      await loader.load();

      await tester.pumpWidget(
        _productionHarness(child: const AppWordmark(name: 'Starter')),
      );
      await tester.pump();

      final name = find.textContaining('Starter');
      final style = tester.widget<Text>(name).style!;
      final effectiveStyle = DefaultTextStyle.of(
        tester.element(name),
      ).style.merge(style);
      final painter = TextPainter(
        text: TextSpan(text: 'Starter', style: effectiveStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      final baseline = painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);

      final squareRect = tester.getRect(find.byWidget(_squareBox(tester)));
      final textTop = tester.getTopLeft(name).dy;
      expect(
        squareRect.bottom - textTop,
        closeTo(baseline, 0.5),
        reason: 'the square bottom must sit on the alphabetic baseline, not the line top',
      );
      expect(
        squareRect.top - textTop,
        closeTo(baseline - style.fontSize! * 0.36, 0.5),
        reason: 'a superscript square would start at or above the cap line',
      );
    });
  });
}

DecoratedBox _squareBox(WidgetTester tester) => tester.widget<DecoratedBox>(
  find
      .byWidgetPredicate(
        (widget) =>
            widget is DecoratedBox &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).color == AppBrandColors.light.markSquare,
      )
      .first,
);

Widget _harness({required Widget child}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: FTheme(
      data: generated.lightTheme,
      child: Scaffold(body: Center(child: child)),
    ),
  );
}

/// The production theme composition: the factory-built light/oxide theme
/// with the brand extension attached, under Onest as the default family.
Widget _productionHarness({required Widget child}) {
  final theme = ForuiThemeFactory.build(
    brightness: Brightness.light,
    accent: AppAccent.oxide,
    fontScale: 1,
    interactionPolicy: AppInteractionPolicy.precisionPointer,
  );
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: FTheme(
      data: theme,
      child: Scaffold(body: Center(child: child)),
    ),
  );
}
