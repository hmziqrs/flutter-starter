import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/fx/shaders/brand_material_surface.dart';
import 'package:starter/shared/fx/shaders/brand_materials.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/marks/material_tile.dart';

void main() {
  group('MaterialTile', () {
    testWidgets('renders the brand material as a square under the outline', (tester) async {
      await tester.pumpWidget(
        _harness(child: MaterialTile(recipe: materialFor('starter'))),
      );

      expect(tester.getSize(find.byType(MaterialTile)), const Size(96, 96));
      expect(find.byType(BrandMaterialSurface), findsOneWidget);

      final outline =
          tester
                  .widget<Container>(
                    find.byWidgetPredicate(
                      (widget) =>
                          widget is Container && widget.foregroundDecoration is ShapeDecoration,
                    ),
                  )
                  .foregroundDecoration!
              as ShapeDecoration;
      expect(outline.color, Colors.transparent);
      final border = (outline.shape as RoundedSuperellipseBorder).side;
      expect(border.color, generated.lightTheme.colors.border);
    });

    testWidgets('sizes a fixed square when given one', (tester) async {
      await tester.pumpWidget(
        _harness(child: MaterialTile(recipe: materialFor('starter'), size: 72)),
      );

      expect(tester.getSize(find.byType(MaterialTile)), const Size(72, 72));
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
