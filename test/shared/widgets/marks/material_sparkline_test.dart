import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/shared/fx/shaders/brand_material_surface.dart';
import 'package:starter/shared/fx/shaders/brand_materials.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;
import 'package:starter/shared/widgets/marks/material_sparkline.dart';

void main() {
  group('MaterialSparkline', () {
    testWidgets('fills the area under a smoothed curve with the material', (tester) async {
      await tester.pumpWidget(
        _harness(
          child: SizedBox(
            width: 300,
            child: MaterialSparkline(
              recipe: materialFor('copper'),
              points: const <double>[0.2, 0.35, 0.3, 0.55, 0.5, 0.75, 0.9],
            ),
          ),
        ),
      );

      expect(find.byType(BrandMaterialSheet), findsOneWidget);
      expect(find.byType(ShaderMask), findsOneWidget);
      expect(find.byType(ClipPath), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('draws the material quad when the series has fewer than two points', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          child: SizedBox(
            width: 200,
            child: MaterialSparkline(recipe: materialFor('copper'), points: const <double>[0.5]),
          ),
        ),
      );

      expect(find.byType(BrandMaterialSheet), findsOneWidget);
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
