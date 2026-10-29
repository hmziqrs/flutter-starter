import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/marks/signature_footer.dart';

final Finder _square = find.descendant(
  of: find.byType(SignatureFooter),
  matching: find.byType(ColoredBox),
);

/// The signature name rides its square inline, so the rendered plain text
/// carries a trailing object-replacement character; match from the start so
/// the copyright line ('© 2026 hmziq.') never matches.
final Finder _name = find.byWidgetPredicate(
  (widget) => widget is Text && (widget.textSpan?.toPlainText() ?? '').startsWith('hmziq'),
);

void main() {
  group('SignatureFooter', () {
    testWidgets('spans name plus square across the container width', (tester) async {
      await tester.pumpWidget(_harness(width: 600));

      final signature = tester.getSize(_name);
      expect(signature.width, closeTo(600, 1.5));
    });

    testWidgets('signs in wordmark weight with a tight line and the trailing square', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(width: 600));

      final name = tester.widget<Text>(_name).style!;
      expect(name.fontWeight, FontWeight.w600);
      expect(name.height, 0.74);
      expect(name.letterSpacing, closeTo(-0.05 * name.fontSize!, 0.001));

      final box = tester.widget<SizedBox>(
        find.ancestor(of: _square, matching: find.byType(SizedBox)).first,
      );
      expect(box.width, closeTo(name.fontSize! * 0.36, 0.001));
      // The signature is a giant wordmark, so the square takes the wordmark's
      // `bg-primary` (wordmark.svelte:44), not the Mark tile's mark-square.
      expect(tester.widget<ColoredBox>(_square).color, generated.lightTheme.colors.primary);
    });

    testWidgets('sits the square inline on the alphabetic baseline', (tester) async {
      await tester.pumpWidget(_harness(width: 600));

      // The square must end exactly at the name's alphabetic baseline, not
      // pinned to the line's top edge like a superscript. The painter
      // replicates the paragraph's effective style.
      final context = tester.element(_name);
      final effectiveStyle = DefaultTextStyle.of(context).style.merge(
        tester.widget<Text>(_name).style,
      );
      final painter = TextPainter(
        text: TextSpan(text: 'hmziq', style: effectiveStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      final baseline = painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
      final textTop = tester.getTopLeft(_name).dy;
      final squareBottom = tester.getRect(_square).bottom;
      expect(squareBottom - textTop, closeTo(baseline, 0.5));
    });

    testWidgets('draws a top border, a clip, and the copyright line under the signature', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(width: 600));

      expect(find.byType(ClipRect), findsOneWidget);
      final bordered = tester.widget<Container>(
        find
            .byWidgetPredicate(
              (widget) =>
                  widget is Container &&
                  widget.decoration is BoxDecoration &&
                  (widget.decoration! as BoxDecoration).border != null,
            )
            .first,
      );
      final border = (bordered.decoration! as BoxDecoration).border! as Border;
      expect(
        border.top.color,
        generated.lightTheme.colors.border,
      );
      expect(border.top.width, greaterThan(0));

      final copyright = tester.widget<Text>(find.text('© 2026 hmziq.')).style!;
      expect(copyright.fontSize, 14);
      expect(copyright.color, generated.lightTheme.colors.mutedForeground);
      expect(
        tester.getTopLeft(find.text('© 2026 hmziq.')).dy,
        greaterThan(tester.getTopLeft(_name).dy),
      );
    });
  });
}

Widget _harness({required double width}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: FTheme(
      data: generated.lightTheme,
      child: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: const SignatureFooter(name: 'hmziq', copyright: '© 2026 hmziq.'),
          ),
        ),
      ),
    ),
  );
}
