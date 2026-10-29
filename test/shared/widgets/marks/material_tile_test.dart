import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/fx/shaders/brand_material_surface.dart';
import 'package:starter/shared/fx/shaders/brand_materials.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/marks/material_tile.dart';

void main() {
  group('MaterialTile', () {
    testWidgets('renders the material as a bare rounded square, no outline', (tester) async {
      await tester.pumpWidget(_harness(child: MaterialTile(recipe: materialFor('starter'))));

      expect(tester.getSize(find.byType(MaterialTile)), const Size(96, 96));
      expect(find.byType(BrandMaterialSurface), findsOneWidget);
      // The kit's tile carries no ring: the material is the tile.
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Container && widget.foregroundDecoration != null,
        ),
        findsNothing,
      );
      // The kit's rounded-[22%]: 22% of the 96 edge.
      final clip = tester.widget<ClipRRect>(find.byType(ClipRRect));
      expect(clip.borderRadius.resolve(TextDirection.ltr).topLeft.x, closeTo(96 * 0.22, 0.001));
    });

    testWidgets('sizes a fixed square when given one', (tester) async {
      await tester.pumpWidget(
        _harness(child: MaterialTile(recipe: materialFor('starter'), size: 72)),
      );

      expect(tester.getSize(find.byType(MaterialTile)), const Size(72, 72));
    });

    testWidgets('circles clip to half the edge', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: MaterialTile(
            recipe: materialFor('starter'),
            size: 48,
            shape: MaterialTileShape.circle,
          ),
        ),
      );

      final clip = tester.widget<ClipRRect>(find.byType(ClipRRect));
      expect(clip.borderRadius.resolve(TextDirection.ltr).topLeft.x, 24);
    });

    testWidgets('a child sits on the page color inside the material frame', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: MaterialTile(
            recipe: materialFor('starter'),
            size: 56,
            child: const Text('Ft', style: TextStyle(fontSize: 56 * 0.34)),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Ft'), findsOneWidget);
      // The kit's framed inset: max(2, round(size * frame)) = round(5.6) = 6,
      // and the inner panel rounds a touch tighter than the tile (18%).
      final panel = tester.widget<DecoratedBox>(
        find.byWidgetPredicate(
          (widget) => widget is DecoratedBox && widget.decoration.color != null,
        ),
      );
      expect(panel.decoration.color, generated.lightTheme.colors.background);
      expect(
        (panel.decoration as BoxDecoration).borderRadius!.resolve(TextDirection.ltr).topLeft.x,
        closeTo(56 * 0.18, 0.001),
      );
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
