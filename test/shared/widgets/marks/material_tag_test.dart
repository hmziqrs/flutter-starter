import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/fx/shaders/brand_material_surface.dart';
import 'package:starter/shared/fx/shaders/brand_materials.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/marks/material_tag.dart';

void main() {
  group('MaterialTag', () {
    testWidgets('runs the material as a 1.5px cover around a 23px pill', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: MaterialTag(recipe: materialFor('copper'), label: 'Pro'),
        ),
      );

      // The kit's pill: 1.5px edge + 2px air + 16px line + 2px air + 1.5px.
      expect(tester.getSize(find.byType(MaterialTag)).height, 23);
      expect(find.byType(BrandMaterialSurface), findsOneWidget);
      expect(find.text('Pro'), findsOneWidget);

      final inner = tester.widget<DecoratedBox>(
        find.byWidgetPredicate(
          (widget) =>
              widget is DecoratedBox &&
              widget.decoration.color == generated.lightTheme.colors.background,
        ),
      );
      expect(
        (inner.decoration as BoxDecoration).borderRadius!.resolve(TextDirection.ltr).topLeft.x,
        11.5,
      );
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
