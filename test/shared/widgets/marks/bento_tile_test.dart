import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/marks/bento_tile.dart';

final Finder _tileBox = find.byWidgetPredicate(
  (widget) =>
      widget is DecoratedBox &&
      widget.decoration is ShapeDecoration &&
      (widget.decoration as ShapeDecoration).shape is RoundedSuperellipseBorder,
);

void main() {
  group('BentoTile', () {
    testWidgets('is a square with a transparent outline and no shadow', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const SizedBox(
            width: 200,
            child: BentoTile(),
          ),
        ),
      );

      expect(tester.getSize(_tileBox), const Size(200, 200));
      final decoration = tester.widget<DecoratedBox>(_tileBox).decoration as ShapeDecoration;
      expect(decoration.color, Colors.transparent);
      expect(decoration.shadows, isNull);
      final border = (decoration.shape as RoundedSuperellipseBorder).side;
      // The tile's ring is the foreground at 10% (bento-tile.svelte
      // ring-foreground/10), not the theme's border token.
      expect(border.color, generated.lightTheme.colors.foreground.withValues(alpha: 0.10));
    });

    testWidgets('sizes a fixed square when given one', (tester) async {
      await tester.pumpWidget(_harness(child: const BentoTile(size: 72)));

      expect(tester.getSize(_tileBox), const Size(72, 72));
    });

    testWidgets('pins its words to the start corner at the kit p-5 inset', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const SizedBox(
            width: 200,
            child: BentoTile(eyebrow: 'freeoxide', title: 'Free Rust tools', body: 'Given away.'),
          ),
        ),
      );

      final tileTopLeft = tester.getTopLeft(_tileBox);
      // p-5: 20dp of air past the tile's 1dp ring.
      expect(tester.getTopLeft(find.text('freeoxide')), tileTopLeft + const Offset(21, 21));
      final order = <double>[
        tester.getTopLeft(find.text('freeoxide')).dy,
        tester.getTopLeft(find.text('Free Rust tools')).dy,
        tester.getTopLeft(find.text('Given away.')).dy,
      ];
      for (var i = 0; i < order.length - 1; i++) {
        expect(order[i], lessThan(order[i + 1]), reason: 'line $i must sit above line ${i + 1}');
      }
    });

    testWidgets('sets the title at 16 w500 with -0.01em and the body muted', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: const BentoTile(title: 'Live links', body: 'Everything on one page.'),
        ),
      );

      final title = tester.widget<Text>(find.text('Live links')).style!;
      expect(title.fontSize, 16);
      expect(title.fontWeight, FontWeight.w500);
      expect(title.letterSpacing, closeTo(-0.01 * 16, 0.001));

      final body = tester.widget<Text>(find.text('Everything on one page.')).style!;
      expect(body.fontSize, 14);
      expect(body.height, 1.625);
      expect(body.color, generated.lightTheme.colors.mutedForeground);
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
