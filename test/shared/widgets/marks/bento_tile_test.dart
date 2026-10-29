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
            child: BentoTile(child: SizedBox.shrink()),
          ),
        ),
      );

      expect(tester.getSize(_tileBox), const Size(200, 200));
      final decoration = tester.widget<DecoratedBox>(_tileBox).decoration as ShapeDecoration;
      expect(decoration.color, Colors.transparent);
      expect(decoration.shadows, isNull);
      final border = (decoration.shape as RoundedSuperellipseBorder).side;
      expect(border.color, generated.lightTheme.colors.border);
    });

    testWidgets('sizes a fixed square when given one', (tester) async {
      await tester.pumpWidget(
        _harness(child: const BentoTile(size: 72, child: SizedBox.shrink())),
      );

      expect(tester.getSize(_tileBox), const Size(72, 72));
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
