import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/fx/shaders/brand_material_surface.dart';
import 'package:starter/shared/fx/shaders/brand_materials.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/marks/material_slider.dart';

void main() {
  group('MaterialSlider', () {
    testWidgets('fills the track with the material up to the thumb', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: SizedBox(
            width: 280,
            child: MaterialSlider(
              recipe: materialFor('copper'),
              value: 0.4,
              onChanged: (_) {},
              semanticLabel: 'Material slider',
            ),
          ),
        ),
      );

      // The material lives only in the fill; the thumb stays a page-colored
      // stud, so exactly one surface paints.
      expect(find.byType(BrandMaterialSurface), findsOneWidget);

      // The kit's thumb: a 20px page-colored circle in a 2px primary border.
      final thumb = tester.widget<Container>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is ShapeDecoration &&
              (widget.decoration! as ShapeDecoration).color ==
                  generated.lightTheme.colors.background,
        ),
      );
      final side = (thumb.decoration! as ShapeDecoration).shape as RoundedSuperellipseBorder;
      expect(side.side.color, generated.lightTheme.colors.primary);
      expect(side.side.width, 2);

      expect(tester.takeException(), isNull);
    });

    testWidgets('dragging reports the new share', (tester) async {
      double reported = 0;
      await tester.pumpWidget(
        _harness(
          child: SizedBox(
            width: 200,
            child: MaterialSlider(
              recipe: materialFor('copper'),
              value: 0,
              onChanged: (value) => reported = value,
            ),
          ),
        ),
      );

      // The drag starts at the strip's center (100 of 200) and moves 50px
      // right, so the final reported share is 150/200.
      await tester.drag(find.byType(MaterialSlider), const Offset(50, 0));
      expect(reported, closeTo(0.75, 0.05));
      expect(tester.takeException(), isNull);
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
